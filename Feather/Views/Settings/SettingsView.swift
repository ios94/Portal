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
        guard _storedSelectedCert >= 0, _storedSelectedCert < _certificates.count else { return nil }
        return _certificates[_storedSelectedCert]
    }

    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            List {
                // MARK: - Modern Header Section
                Section {
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 90, height: 90)
                        }
                        
                        VStack(spacing: 4) {
                            Text("AshteMobile")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("Fast & Secure Signing")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 15) {
                            SocialButton(title: "Telegram", icon: "paperplane.fill", color: Color(hex: "0088cc")) {
                                UIApplication.shared.open(URL(string: "https://t.me/ashtemobile")!)
                            }
                            SocialButton(title: "Instagram", icon: "camera.fill", color: Color.pink) {
                                UIApplication.shared.open(URL(string: "https://www.instagram.com/ashtemobile")!)
                            }
                        }
                        .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }

                // MARK: - General Section
                Section(header: Text("گشتی")) {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            FRAppIconView(size: 26)
                            Text(.localized("About"))
                                .padding(.leading, 5)
                        }
                    }
                    
                    SettingsRow(title: "Appearance", icon: "paintbrush.fill", color: .purple, destination: AppearanceView())
                    SettingsRow(title: "App Icon", icon: "app.badge.fill", color: .blue, destination: AppIconView(currentIcon: $_currentIcon))
                }
                
                // MARK: - Certificates Section
                Section(header: Text(.localized("Certificates")), footer: Text(.localized("Add and manage certificates used for signing applications."))) {
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text(.localized("No Certificate"))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    NavigationLink(destination: CertificatesView()) {
                        Label {
                            Text(.localized("Manage Certificates"))
                        } icon: {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // MARK: - Features Section
                Section(header: Text(.localized("Features")), footer: Text(.localized("Configure signing, compression, and installation options."))) {
                    SettingsRow(title: "Signing Options", icon: "signature", color: .orange, destination: ConfigurationView())
                    SettingsRow(title: "Archive & Compression", icon: "archivebox.fill", color: .brown, destination: ArchiveView())
                    SettingsRow(title: "Installation", icon: "arrow.down.circle.fill", color: .blue, destination: InstallationView())
                }
                
                // MARK: - Directories Section
                Section(header: Text(.localized("Misc"))) {
                    QuickLinkRow(title: "Open Documents", icon: "folder.fill", color: .gray) {
                        UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!)
                    }
                    QuickLinkRow(title: "Open Archives", icon: "archivebox.fill", color: .gray) {
                        UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!)
                    }
                    QuickLinkRow(title: "Open Certificates", icon: "lock.folder.fill", color: .gray) {
                        UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!)
                    }
                }
                
                // MARK: - Danger Zone
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset All Data"), systemImage: "trash.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
        }
    }
}

// MARK: - Helper Components
struct SocialButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(color)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRow<Destination: View>: View {
    let title: String
    let icon: String
    let color: Color
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 8).fill(color))
                Text(.localized(title))
                    .padding(.leading, 5)
            }
        }
    }
}

struct QuickLinkRow: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(RoundedRectangle(cornerRadius: 8).fill(color))
                Text(.localized(title))
                    .foregroundColor(.primary)
                    .padding(.leading, 5)
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
