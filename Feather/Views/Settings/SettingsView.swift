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
            List {
                // MARK: - Modern Profile Header
                Section {
                    VStack(spacing: 14) {
                        // لۆگۆی ئەپەکە بە دیزاینی مۆدێرن
                        AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                            image.resizable()
                                .scaledToFit()
                                .frame(width: 85, height: 85)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                        } placeholder: {
                            ProgressView()
                                .frame(width: 85, height: 85)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        
                        VStack(spacing: 4) {
                            Text("AshteMobile")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Premium Signing Experience")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        // دوگمەی سۆشیاڵ میدیاکان بە شێوازی Capsule
                        HStack(spacing: 12) {
                            socialButton(icon: "paperplane.fill", text: "Telegram", color: Color.blue, url: "https://t.me/ashtemobile")
                            
                            socialButton(icon: "camera.fill", text: "Instagram", color: Color.pink, url: "https://www.instagram.com/ashtemobile")
                        }
                        .padding(.top, 5)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // MARK: - General Section
                Section {
                    NavigationLink(destination: AboutView()) {
                        HStack(spacing: 14) {
                            FRAppIconView(size: 28)
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                            Text(verbatim: .localized("About %@", arguments: Bundle.main.name))
                                .font(.system(size: 16))
                        }
                    }
                    NavigationLink(destination: AppearanceView()) {
                        modernLabel(.localized("Appearance"), systemImage: "paintbrush.fill", color: .purple)
                    }
                    NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
                        modernLabel(.localized("App Icon"), systemImage: "app.badge.fill", color: .indigo)
                    }
                }
                
                // MARK: - Certificates Section
                NBSection(.localized("Certificates")) {
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(.localized("No Certificate"))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    NavigationLink(destination: CertificatesView()) {
                        modernLabel(.localized("Manage Certificates"), systemImage: "checkmark.seal.fill", color: .green)
                    }
                } footer: {
                    Text(.localized("Add and manage certificates used for signing applications."))
                }
                
                // MARK: - Features Section
                NBSection(.localized("Features")) {
                    NavigationLink(destination: ConfigurationView()) {
                        modernLabel(.localized("Signing Options"), systemImage: "signature", color: .orange)
                    }
                    NavigationLink(destination: ArchiveView()) {
                        modernLabel(.localized("Archive & Compression"), systemImage: "archivebox.fill", color: .brown)
                    }
                    NavigationLink(destination: InstallationView()) {
                        modernLabel(.localized("Installation"), systemImage: "arrow.down.circle.fill", color: .blue)
                    }
                } footer: {
                    Text(.localized("Configure the apps way of installing, its zip compression levels, and custom modifications to apps."))
                }
                
                // MARK: - Directories Section
                NBSection(.localized("Misc")) {
                    Button(action: { UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!) }) {
                        modernLabel(.localized("Open Documents"), systemImage: "folder.fill", color: .gray)
                    }
                    Button(action: { UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!) }) {
                        modernLabel(.localized("Open Archives"), systemImage: "shippingbox.fill", color: .gray)
                    }
                    Button(action: { UIApplication.open(FileManager.default.certificates.toSharedDocumentsURL()!) }) {
                        modernLabel(.localized("Open Certificates"), systemImage: "lock.rectangle.fill", color: .gray)
                    }
                }
                
                // MARK: - Danger Zone Section
                Section {
                    NavigationLink(destination: ResetView()) {
                        HStack(spacing: 14) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                            
                            Text(.localized("Reset All Data"))
                                .font(.system(size: 16))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped) // ستایلی مۆدێرنی ئەپڵ
        }
    }
}

// MARK: - Modern UI Helpers (سەد لە سەد کاردەکات بەبێ کێشە)
extension SettingsView {
    
    @ViewBuilder
    private func modernLabel(_ text: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
    }
    
    @ViewBuilder
    private func socialButton(icon: String, text: String, color: Color, url: String) -> some View {
        Button(action: {
            if let targetURL = URL(string: url) {
                UIApplication.shared.open(targetURL)
            }
        }) {
            HStack {
                Image(systemName: icon)
                Text(text)
                    .fontWeight(.bold)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(color)
            .clipShape(Capsule())
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
