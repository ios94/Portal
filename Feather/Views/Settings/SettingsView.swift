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
                // MARK: - Modern Profile Header
                Section {
                    VStack(spacing: 20) {
                        // Profile Image with Animation
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 110, height: 110)
                            
                            AsyncImage(url: URL(string: "https://ashtemobile.tututweak.com/a.png")) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 90, height: 90)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 22))
                            }
                        }
                        .padding(.top, 10)
                        
                        VStack(spacing: 6) {
                            Text("AshteMobile")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Version \(Bundle.main.version) (\(Bundle.main.build))")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        // Social Links Card
                        HStack(spacing: 15) {
                            _socialLink(icon: "paperplane.fill", title: "Telegram", color: .blue, url: "https://t.me/ashtemobile")
                            _socialLink(icon: "camera.fill", title: "Instagram", color: .pink, url: "https://www.instagram.com/ashtemobile")
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                // MARK: - App Preferences
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        _modernLabel("Appearance", icon: "paintbrush.fill", color: .purple)
                    }
                    NavigationLink(destination: AppIconView(currentIcon: $_currentIcon)) {
                        _modernLabel("App Icon", icon: "app.badge.fill", color: .indigo)
                    }
                    NavigationLink(destination: AboutView()) {
                        _modernLabel("About Feather", icon: "info.circle.fill", color: .blue)
                    }
                } header: { Text("Preferences") }
                
                // MARK: - Certificate Management
                Section {
                    if let cert = selectedCertificate {
                        NavigationLink(destination: CertificatesView()) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    _modernLabel("Active Certificate", icon: "checkmark.seal.fill", color: .green)
                                    Spacer()
                                    Text("Active").font(.caption2).bold().padding(4).background(Color.green.opacity(0.2)).foregroundColor(.green).cornerRadius(5)
                                }
                                CertificatesCellView(cert: cert)
                                    .scaleEffect(0.9)
                                    .padding(.leading, -15)
                            }
                        }
                    } else {
                        NavigationLink(destination: CertificatesView()) {
                            _modernLabel("Manage Certificates", icon: "shield.slash.fill", color: .orange)
                        }
                    }
                } header: { Text("Security") }
                
                // MARK: - Advanced Features
                Section {
                    NavigationLink(destination: ConfigurationView()) {
                        _modernLabel("Signing Options", icon: "signature", color: .orange)
                    }
                    NavigationLink(destination: ArchiveView()) {
                        _modernLabel("Archive & Compression", icon: "archivebox.fill", color: .brown)
                    }
                    NavigationLink(destination: InstallationView()) {
                        _modernLabel("Installation", icon: "arrow.down.circle.fill", color: .blue)
                    }
                } header: { Text("Tools") }
                
                // MARK: - File Manager
                Section {
                    _fileRow(title: "Open Documents", icon: "folder.fill", color: .gray, path: URL.documentsDirectory)
                    _fileRow(title: "Open Archives", icon: "shippingbox.fill", color: .gray, path: FileManager.default.archives)
                    _fileRow(title: "Open Certificates", icon: "lock.rectangle.fill", color: .gray, path: FileManager.default.certificates)
                } header: { Text("Storage") }
                
                // MARK: - System
                Section {
                    NavigationLink(destination: ResetView()) {
                        HStack {
                            _modernLabel("Reset All Data", icon: "trash.fill", color: .red)
                            Spacer()
                        }
                    }
                } header: { Text("System") }
                
                // Footer
                Section {
                    VStack(alignment: .center, spacing: 8) {
                        Text("Made with ❤️ by AshteMobile Team")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - UI Components
extension SettingsView {
    
    @ViewBuilder
    private func _modernLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Text(.localized(title))
                .font(.system(size: 16, weight: .medium))
        }
    }
    
    @ViewBuilder
    private func _socialLink(icon: String, title: String, color: Color, url: String) -> some View {
        Button(action: { UIApplication.shared.open(URL(string: url)!) }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func _fileRow(title: String, icon: String, color: Color, path: URL) -> some View {
        Button(action: { UIApplication.open(path.toSharedDocumentsURL()!) }) {
            _modernLabel(title, icon: icon, color: color)
        }
        .buttonStyle(.plain)
    }
}
