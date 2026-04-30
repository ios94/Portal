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
    @State private var searchText = ""
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(5))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            NBNavigationView("Discover") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        
                        // MARK: - Premium Hero Carousel
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        AppStoreHeroCard(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 340)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .padding(.top, 10)
                        }
                        
                        // MARK: - Modern Horizontal Sections
                        VStack(alignment: .leading, spacing: 35) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack(alignment: .lastTextBaseline) {
                                        Text(category)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                        Spacer()
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(Color(UIColor.tertiaryLabel))
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 20) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    ModernCompactCard(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 10)
                                    }
                                }
                            }
                        }
                        
                        ModernSocialFooter()
                            .padding(.top, 20)
                            .padding(.bottom, 50)
                    }
                }
                .background(Color(UIColor.systemBackground).ignoresSafeArea())
                .refreshable { await loadApps() }
            }
            .searchable(text: $searchText, prompt: "Games, Apps, and more...")
            .onAppear { Task { await loadApps() } }
            
            // MARK: - Glassmorphic Notification
            if showNotification, let app = downloadedApp {
                GlassNotification(app: app)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.9)))
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut) { self.showNotification = false }
        }
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            await MainActor.run { self.apps = decoded }
        } catch { print("Error: \(error)") }
    }
}

// MARK: - Premium UI Components

struct AppStoreHeroCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.15)
            }
            .frame(width: UIScreen.main.bounds.width - 48, height: 320)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            
            // Premium Gradient Overlay
            LinearGradient(
                stops: [
                    Gradient.Stop(color: .clear, location: 0.3),
                    Gradient.Stop(color: .black.opacity(0.9), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            
            VStack(alignment: .leading, spacing: 8) {
                Text(app.status?.uppercased() ?? "FEATURED")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(app.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(app.category ?? "Essential App")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(24)
        }
        .padding(.horizontal, 24)
        .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
    }
}

struct ModernCompactCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(height: 36, alignment: .top)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .frame(width: 100)
    }
}

// MARK: - Modernized Detail View
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: Stretchy Header with Blur Fade
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .global).minY
                    let height = minY > 0 ? 350 + minY : 350

                    ZStack(alignment: .top) {
                        AsyncImage(url: app.fullBannerURL ?? app.fullImageURL) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.blue.opacity(0.2)
                        }
                        .frame(width: proxy.size.width, height: height)
                        .clipped()
                        .offset(y: minY > 0 ? -minY : 0)
                        
                        // Fade to Background Color
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.5),
                                .init(color: Color(UIColor.systemBackground), location: 1.0)
                            ],
                            startPoint: .top, endPoint: .bottom
                        )
                        .frame(width: proxy.size.width, height: height)
                        .offset(y: minY > 0 ? -minY : 0)
                        
                        // Glassmorphic Nav Bar
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            Spacer()
                            Button(action: shareApp) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, safeAreaTop() + 10)
                    }
                }
                .frame(height: 300) // Adjusted to overlap nicely
                
                // MARK: App Info Header Overlap
                HStack(alignment: .bottom, spacing: 20) {
                    AsyncImage(url: app.fullImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 30).stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(app.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(app.developer ?? "AshteMobile")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                            .frame(width: 100)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .offset(y: -40)
                .padding(.bottom, -20)
                
                // MARK: Stats Row (App Store Style)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 30) {
                        StatItem(title: "RATINGS", value: "4.8", subtitle: "★★★★★")
                        Divider().frame(height: 40)
                        StatItem(title: "CATEGORY", value: app.category ?? "App", subtitle: "Utilities")
                        Divider().frame(height: 40)
                        StatItem(title: "SIZE", value: app.size ?? "N/A", subtitle: "MB")
                        Divider().frame(height: 40)
                        StatItem(title: "VERSION", value: app.version ?? "1.0", subtitle: "Latest")
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 30)
                
                Divider().padding(.horizontal, 24).padding(.bottom, 24)
                
                // MARK: Description
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's Included")
                        .font(.title2.bold())
                    
                    if let hacks = app.hack, !hacks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(hacks, id: \.self) { hack in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 18))
                                    Text(hack)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("Get the best experience with \(app.name). Updated regularly for maximum stability and performance.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(6)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .ignoresSafeArea(edges: .top)
    }
    
    private func shareApp() {
        let text = "Check out \(app.name) on AshteMobile!\nhttps://t.me/ashtemmobile"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(av, animated: true, completion: nil)
    }
    
    private func safeAreaTop() -> CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 44
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)
            Text(value).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.primary)
            Text(subtitle).font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
        }
    }
}

// MARK: - Glass Notification
struct GlassNotification: View {
    let app: HomeApp
    
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.gray }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Added to Library")
                    .font(.system(size: 15, weight: .bold))
                Text(app.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "arrow.down.app.fill")
                .foregroundColor(.blue)
                .font(.title2)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.primary.opacity(0.05), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
    }
}

// MARK: - App Store Style Download Button
struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        ZStack {
            if downloader.isFinished {
                Button(action: {}) {
                    Text("OPEN")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.tertiarySystemFill))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .disabled(true)
            } else if downloader.isDownloading {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.systemGray5), lineWidth: 3)
                        .frame(width: 28, height: 28)
                    
                    if downloader.progress > 0 {
                        Circle()
                            .trim(from: 0, to: downloader.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .frame(width: 28, height: 28)
                            .animation(.linear(duration: 0.2), value: downloader.progress)
                    }
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .onTapGesture { downloader.stop() }
                }
                .frame(height: 32)
            } else {
                Button(action: {
                    if let downloadURL = URL(string: app.url) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        downloader.start(url: downloadURL) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            DispatchQueue.main.async { onDownloadComplete() }
                        }
                    }
                }) {
                    Text("GET")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color(UIColor.tertiarySystemFill))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain) 
            }
        }
        .frame(height: 32)
    }
}

// MARK: - Modern Social Footer
struct ModernSocialFooter: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(Color(UIColor.tertiaryLabel))
            
            Text("Stay Connected")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            HStack(spacing: 16) {
                SocialPill(icon: "paperplane.fill", title: "Telegram", color: .blue, url: "https://t.me/ashtemobile")
                SocialPill(icon: "camera.fill", title: "Instagram", color: .pink, url: "https://www.instagram.com/ashtemobile")
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .padding(.horizontal, 24)
    }
}

struct SocialPill: View {
    let icon: String; let title: String; let color: Color; let url: String
    var body: some View {
        Button(action: { UIApplication.shared.open(URL(string: url)!) }) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(color)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Downloader Logic
class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    
    private var downloadTask: URLSessionDownloadTask?
    private var session: URLSession?
    private var downloadURL: URL?
    private var onFinished: ((URL) -> Void)?
    
    func start(url: URL, onFinished: @escaping (URL) -> Void) {
        self.downloadURL = url; self.onFinished = onFinished; self.isDownloading = true; self.progress = 0; self.isFinished = false
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue.main)
        downloadTask = session?.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    func stop() {
        downloadTask?.cancel(); session?.invalidateAndCancel(); self.isDownloading = false; self.progress = 0
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            DispatchQueue.main.async { self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite) }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)-\(downloadURL?.lastPathComponent ?? "app.ipa")")
        try? FileManager.default.removeItem(at: destinationURL)
        do {
            try FileManager.default.copyItem(at: location, to: destinationURL)
            DispatchQueue.main.async {
                self.isDownloading = false; self.isFinished = true; self.onFinished?(destinationURL)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { self.isFinished = false } }
            }
        } catch { DispatchQueue.main.async { self.isDownloading = false } }
        session.finishTasksAndInvalidate()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil { DispatchQueue.main.async { self.isDownloading = false } }
        session.finishTasksAndInvalidate()
    }
}
