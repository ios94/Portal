import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @State private var _showMethodChangedAlert = false

    private let _installationMethods: [String] = [
        .localized("Server"),
        .localized("idevice")
    ]
    
    // MARK: Body
    var body: some View {
        NBList(.localized("Installation")) {
            
            // --- گۆڕینی شێوازی هەڵبژاردن بۆ Segmented (دوو خانەی تەنیشت یەک) ---
            Section {
                Picker("", selection: $_installationMethod) {
                    ForEach(_installationMethods.indices, id: \.self) { index in
                        Text(_installationMethods[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented) // ئەمە شێوەکەی دەکات بەو دوو خانەیەی تەنیشت یەک
                .listRowBackground(Color.clear) // بۆ ئەوەی جوانتر دیار بێت لەناو لیستەکە
            } footer: {
                // ڕوونکردنەوەکان
                Text(.localized("Server (Recommended):\nUses a locally hosted server and itms-services:// to install applications.\n\nIDevice (advanced):\nUses a VPN and a pairing file. Writes to AFC and manually calls installd, while monitoring install progress by using a callback\nAdvantage: It is very reliable, does not need SSL certificates or a externally hosted server. Rather, works similarly to a computer."))
                    .padding(.top, 5)
            }
            
            // --- ڤیووەکان کە بەپێی هەڵبژاردنەکە دەگۆڕێن ---
            Section {
                if _installationMethod == 0 {
                    ServerView()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                } else if _installationMethod == 1 {
                    TunnelView()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
        }
        .onChange(of: _installationMethod) { newValue in
            // ئەگەر چوو سەر idevice ئاگادارییەکە پیشان بدات
            guard newValue == 1 else { return }
            _showMethodChangedAlert = true
        }
        .alert(.localized("Advanced Installation Method"), isPresented: $_showMethodChangedAlert) {
            Button(.localized("Switch Back"), role: .destructive) {
                _installationMethod = 0
            }
            Button(.localized("OK"), role: .cancel) {}
        } message: {
            Text(.localized("idevice warning"))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: _installationMethod) // ئەنیمەیشنێکی نەرم کاتی گۆڕین
    }
}
