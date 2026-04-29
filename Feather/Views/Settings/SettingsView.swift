import SwiftUI
import NimbleViews
import UIKit
import Darwin
import IDeviceSwift

// MARK: - View
struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
    @State private var _currentIcon: String? = UIApplication.shared.alternateIconName
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    private var selectedCertificate: CertificatePair? {
        guard
            _storedSelectedCert >= 0,
            _storedSelectedCert < _certificates.count
        else {
            return nil
        }
        return _certificates[_storedSelectedCert]
    }

    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                // MARK: - Modern Header (Logo & Social)
                Section {
                    VStack(spacing: 15) {
                        AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 85, height: 85)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                                .shadow(radius: 5)
                        } placeholder: {
                            ProgressView()
                        }
                        
                        Text("AshteMobile")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                        
                        HStack(spacing: 20) {
                            // Telegram Button
                            Button(action: {
                                if let url = URL(string: "https://t.me/ashtemobile") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.blue))
                            }
                            
                            // Instagram Button
                            Button(action: {
                                if let url = URL(string: "https://www.instagram.com/ashtemobile") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Image(systemName: "camera.fill")
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Circle().fill(Color.pink))
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .listRowBackground(Color.clear)

                // MARK: - About & Appearance
                Section {
                    NavigationLink(destination: AboutView()) {
                        Label {
                            Text(verbatim: .localized("About %@", arguments: Bundle.main.name))
                        } icon: {
                            FRAppIconView(size: 23)
                        }
                    }
                    NavigationLink(destination: AppearanceView()) {
                        Label(.localized("Appearance"), systemImage: "paintbrush.fill")
                            .foregroundColor(.purple)
                    }
                    NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
                        Label(.localized("App Icon"), systemImage: "app.badge.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                // MARK: - Certificates
                NBSection(.localized("Certificates")) {
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                    } else {
                        Text(.localized("No Certificate"))
                            .font(.footnote)
                            .foregroundColor(.disabled())
                    }
                    NavigationLink(destination: CertificatesView()) {
                        Label(.localized("Manage Certificates"), systemImage: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }
                } footer: {
                    Text(.localized("Add and manage certificates used for signing applications."))
                }
                
                // MARK: - Features
                NBSection(.localized("Features")) {
                    NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "signature")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: ArchiveView()) {
                        Label(.localized("Archive & Compression"), systemImage: "archivebox.fill")
                            .foregroundColor(.brown)
                    }
                    NavigationLink(destination: InstallationView()) {
                        Label(.localized("Installation"), systemImage: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                    }
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, and custom modifications to apps."))
                }
                
                // MARK: - Directories
                NBSection(.localized("Misc")) {
                    Button {
                        UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
                    } label: {
                        Label(.localized("Open Documents"), systemImage: "folder.fill")
                    }
                    
                    Button {
                        UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
                    } label: {
                        Label(.localized("Open Archives"), systemImage: "archivebox.fill")
                    }
                    
                    Button {
                        UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!)
                    } label: {
                        Label(.localized("Open Certificates"), systemImage: "lock.folder.fill")
                    }
                }
                
                // MARK: - Reset
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset All Data"), systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}
