//
//  HomeView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - Models
struct HomeApp: Codable, Identifiable {
    var id: String { url }
    let name: String
    let version: String?
    let category: String?
    let image: String?
    let size: String?
    let developer: String?
    let bundle: String?
    let url: String
    let status: String?
    let banner: String?
    let hack: [String]?

    var fullImageURL: URL? {
        guard let img = image else { return nil }
        return URL(string: "https://ashtemobile.tututweak.com/\(img)")
    }
    
    var fullBannerURL: URL? {
        if let ban = banner {
            return URL(string: "https://ashtemobile.tututweak.com/\(ban)")
        }
        return fullImageURL
    }
}

// MARK: - Main Home View
struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    
    @State private var currentBanner = 0
    let myCustomBanners = [
        "https://raw.githubusercontent.com/mzerem18-cpu/Portal/refs/heads/main/Images/aste.png",
        "https://raw.githubusercontent.com/mzerem18-cpu/Portal/refs/heads/main/Images/app.png"
    ]
    
    let myCustomLinks = [
        "https://t.me/ashtemobile",
        "https://www.instagram.com/ashtemobile"
    ]
    
    let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            NBNavigationView("Discover") {
                ScrollView {
                    VStack(spacing: 35) {
                        
                        // Banners
                        if !myCustomBanners.isEmpty {
                            TabView(selection: $currentBanner) {
                                ForEach(0..<myCustomBanners.count, id: \.self) { index in
                                    Button(action: {
                                        if index < myCustomLinks.count, let url = URL(string: myCustomLinks[index]) {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        AsyncImage(url: URL(string: myCustomBanners[index])) { image in
                                            image.resizable()
                                                 .aspectRatio(contentMode: .fill)
                                        } placeholder: {
                                            Color(UIColor.secondarySystemBackground)
                                                .overlay(Image(systemName: "photo").foregroundColor(.gray.opacity(0.5)))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .tag(index)
                                }
                            }
                            .frame(height: (UIScreen.main.bounds.width - 40) * (1948.0 / 3464.0))
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .padding(.horizontal, 20)
                            .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .onReceive(timer) { _ in
                                guard !myCustomBanners.isEmpty else { return }
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentBanner = (currentBanner + 1) % myCustomBanners.count
                                }
                            }
                        }
                        
                        // Categories
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(alignment: .lastTextBaseline) {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text("See All")
                                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 16) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    HomeAppCardView(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 15)
                                        .padding(.top, 5)
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 40)
                    }
                    .padding(.top, 15)
                }
                .refreshable {
                    await loadApps()
                }
            }
            .onAppear {
                Task { await loadApps() }
            }
            
            if showNotification, let app = downloadedApp {
                notificationBanner(for: app)
                    .padding(.top, safeAreaTop() + 10)
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            self.showNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                self.showNotification = false
            }
        }
    }
    
    @ViewBuilder
    private func notificationBanner(for app: HomeApp) -> some View {
        HStack(alignment: .center, spacing: 14) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(UIColor.secondarySystemBackground)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            VStack(alignment: .leading, spacing: 3) {
                Text("App Processed")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("\(app.name) is ready.")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 24))
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
            }
        } catch {
            print("Error loading: \(error)")
        }
    }
    
    private func safeAreaTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return window?.safeAreaInsets.top ?? 44
    }
}

// MARK: - App Detail View
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    
                    GeometryReader { proxy in
                        let minY = proxy.frame(in: .global).minY
                        let isScrolledDown = minY > 0
                        let height = isScrolledDown ? 280 + minY : 280
                        let offset = isScrolledDown ? -minY : 0

                        ZStack(alignment: .top) {
                            AsyncImage(url: app.fullImageURL) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color(UIColor.secondarySystemBackground)
                            }
                            .frame(width: proxy.size.width, height: height)
                            .clipped()
                            .overlay(
                                LinearGradient(colors: [.clear, Color(UIColor.systemBackground)], startPoint: .center, endPoint: .bottom)
                            )
                            .offset(y: offset)
                            
                            HStack {
                                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                                Spacer()
                                
                                Button(action: {
                                    let shareText = "Download \(app.name) from AshteMobile Store!\nhttps://t.me/ashtemmobile"
                                    let av = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
                                    UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
                                }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                        .frame(width: 40, height: 40)
                                        .background(.ultraThinMaterial)
                                        .clipShape(Circle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, safeAreaTop() + 10)
                        }
                    }
                    .frame(height: 280)
                    
                    HStack(alignment: .center, spacing: 16) {
                        AsyncImage(url: app.fullImageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color(UIColor.secondarySystemBackground)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(app.name)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(app.developer ?? "AshteMobile")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                            
                            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                                .frame(width: 85)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .offset(y: -40)
                    .padding(.bottom, -20)
                    
                    HStack(spacing: 12) {
                        StatCard(icon: "tag.fill", title: "Version", value: app.version ?? "1.0", color: .blue)
                        StatCard(icon: "shippingbox.fill", title: "Size", value: app.size ?? "Unknown", color: .purple)
                        StatCard(icon: "square.grid.2x2.fill", title: "Category", value: app.category ?? "App", color: .orange)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Description")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            if let hacks = app.hack, !hacks.isEmpty {
                                ForEach(hacks, id: \.self) { hack in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 6))
                                            .padding(.top, 6)
                                        Text(hack)
                                            .font(.system(size: 15, weight: .regular, design: .rounded))
                                            .foregroundColor(.secondary)
                                            .lineSpacing(4)
                                    }
                                }
                            } else {
                                Text("Download \(app.name) now and enjoy smooth performance and regular updates directly from the AshteMobile Store.")
                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Information")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 0) {
                            AppInfoRow(title: "Source", value: "AshteMobile Repo", isLast: false)
                            AppInfoRow(title: "Developer", value: app.developer ?? "Unknown", isLast: false)
                            AppInfoRow(title: "Size", value: app.size ?? "Unknown", isLast: false)
                            AppInfoRow(title: "Version", value: app.version ?? "1.0", isLast: false)
                            AppInfoRow(title: "Identifier", value: app.bundle ?? "com.ashte.\(app.name.replacingOccurrences(of: " ", with: "").lowercased())", isLast: true)
                        }
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 50)
                }
            }
            .navigationBarHidden(true)
            .ignoresSafeArea(edges: .top)
        }
    }
    
    private func safeAreaTop() -> CGFloat {
        let window = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        return window?.safeAreaInsets.top ?? 44
    }
}

// MARK: - Components
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AppInfoRow: View {
    let title: String
    let value: String
    let isLast: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            
            if !isLast {
                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}

struct HomeAppCardView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(UIColor.secondarySystemBackground)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
            
            VStack(spacing: 2) {
                Text(app.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 5)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .padding(14)
        .frame(width: 135, height: 200)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct SocialMediaFooter: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Connect With Us")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 24) {
                SocialButton(icon: "paperplane.fill", color: .blue, url: "https://t.me/ashtemobile")
                SocialButton(icon: "camera.fill", color: Color(UIColor.systemPurple), url: "https://www.instagram.com/ashtemobile")
                SocialButton(icon: "play.tv.fill", color: .primary, url: "https://www.tiktok.com/@ashtemobile")
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
    }
}

struct SocialButton: View {
    let icon: String
    let color: Color
    let url: String
    
    var body: some View {
        Button(action: {
            if let link = URL(string: url) {
                UIApplication.shared.open(link)
            }
        }) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Downloader
class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?
    
    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url
        self.onFinished = onFinished
        self.isDownloading = true
        self.progress = 0
        self.isFinished = false
        
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func stop() {
        downloadTask?.cancel()
        session?.invalidateAndCancel()
        self.isDownloading = false
        self.progress = 0
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            DispatchQueue.main.async {
                self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "\(UUID().uuidString)-\(downloadURL?.lastPathComponent ?? "app.ipa")"
        let destinationURL = tempDir.appendingPathComponent(fileName)
        
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.isDownloading = false
                self.isFinished = true
                self.onFinished?(destinationURL)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.isFinished = false
                    }
                }
            }
        } catch {
            DispatchQueue.main.async { self.isDownloading = false }
        }
        session.finishTasksAndInvalidate()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil {
            DispatchQueue.main.async { self.isDownloading = false }
        }
        session.finishTasksAndInvalidate()
    }
}

// MARK: - THE BUTTON LOGIC
struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    @StateObject private var downloader = HomeAppDownloader()
    
    // ئەمە ئەوەیە کە دەزانێت تۆ کامیانت هەڵبژاردووە لە ڕێکخستنەکان
    @AppStorage("Feather.installationMethod") private var installationMethod: Int = 0
    
    var body: some View {
        ZStack {
            if downloader.isFinished {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
                    .transition(.scale.combined(with: .opacity))
            } else if downloader.isDownloading {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 26, height: 26)
                    
                    if downloader.progress > 0 {
                        Circle()
                            .trim(from: 0, to: downloader.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 26, height: 26)
                            .animation(.linear(duration: 0.2), value: downloader.progress)
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation { downloader.stop() }
                        }
                }
                .frame(height: 30)
            } else {
                Button(action: {
                    if let downloadURL = URL(string: app.url) {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        withAnimation {
                            downloader.start(url: downloadURL) { localURL in
                                
                                // مەرجی سەرەکی لێرە جێبەجێ کراوە
                                if installationMethod == 0 {
                                    // ئەگەر On Server بوو: دەبێت فایلی دابەزێنراو ڕاستەوخۆ بنێرین بۆ واژووکردن
                                    
                                    let id = "DirectInstall_\(UUID().uuidString)"
                                    let downloadSession = downloadManager.startArchive(from: localURL, id: id)
                                    
                                    do {
                                        try downloadManager.handlePachageFile(url: localURL, dl: downloadSession)
                                        // نامەیەک دەنێرین بۆ سیستەمەکە کە پەنجەرەی ئینستاڵەکە ڕاستەوخۆ بکاتەوە
                                        NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: nil)
                                    } catch {
                                        print("Error preparing direct install: \(error)")
                                    }
                                } else {
                                    // ئەگەر On Device بوو: دەچێتە ناو فۆڵدەری Library
                                    _ = downloadManager.startDownload(from: localURL)
                                }
                                
                                DispatchQueue.main.async {
                                    onDownloadComplete()
                                }
                            }
                        }
                    }
                }) {
                    Text("GET")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle()) 
            }
        }
        .animation(.spring(), value: downloader.isDownloading)
        .animation(.spring(), value: downloader.isFinished)
    }
}
