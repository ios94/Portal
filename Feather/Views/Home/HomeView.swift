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

// MARK: - Main Home View (Ultra Clean iOS 17+ Style)
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
            Color(UIColor.systemBackground).ignoresSafeArea() // Clean White/Black Background
            
            NBNavigationView("Discover") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        
                        // MARK: - Minimalist Featured Slider
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        CleanHeroCard(app: app)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 280)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .padding(.top, 10)
                        }
                        
                        // MARK: - Clean App Rows
                        VStack(alignment: .leading, spacing: 35) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                    .padding(.horizontal, 24)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 20) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    CleanCompactCard(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                        
                        SimpleFooterView()
                            .padding(.bottom, 50)
                            .padding(.top, 20)
                    }
                }
                .refreshable { await loadApps() }
            }
            .searchable(text: $searchText, prompt: "Search apps, games...")
            .onAppear { Task { await loadApps() } }
            
            // Notification
            if showNotification, let app = downloadedApp {
                CleanNotification(app: app)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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

// MARK: - Clean UI Components

struct CleanHeroCard: View {
    let app: HomeApp
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(UIColor.secondarySystemBackground)
            }
            .frame(width: UIScreen.main.bounds.width - 48, height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            // Smooth inner gradient
            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(app.status?.uppercased() ?? "FEATURED")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.white.opacity(0.8))
                
                Text(app.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                Text(app.category ?? "App")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(24)
        }
        .padding(.horizontal, 24)
    }
}

struct CleanCompactCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color(UIColor.secondarySystemBackground)
            }
            .frame(width: 105, height: 105)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.category ?? "App")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .frame(width: 105)
    }
}

struct CleanNotification: View {
    let app: HomeApp
    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.gray.opacity(0.2) }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Ready in Library")
                    .font(.system(size: 14, weight: .bold))
                Text(app.name)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)
        }
        .padding(14)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 24)
    }
}

struct SimpleFooterView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Follow AshteMobile")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
            
            HStack(spacing: 24) {
                Button(action: { UIApplication.shared.open(URL(string: "https://t.me/ashtemobile")!) }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                        .frame(width: 50, height: 50)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: { UIApplication.shared.open(URL(string: "https://instagram.com/ashtemobile")!) }) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.pink)
                        .frame(width: 50, height: 50)
                        .background(Color.pink.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bento Box Detail View
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                
                // Top Nav
                HStack {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Button(action: shareApp) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(width: 40, height: 40)
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, safeAreaTop() + 10)
                
                // App Header
                VStack(spacing: 16) {
                    AsyncImage(url: app.fullImageURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color(UIColor.secondarySystemBackground)
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.primary.opacity(0.05), lineWidth: 1))
                    
                    VStack(spacing: 6) {
                        Text(app.name)
                            .font(.system(size: 24, weight: .bold))
                            .multilineTextAlignment(.center)
                        
                        Text(app.developer ?? "AshteMobile")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    // Big Action Button
                    HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete, isLarge: true)
                        .frame(width: 160)
                        .padding(.top, 8)
                }
                
                // Bento Box Info Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    BentoInfoBox(icon: "tag.fill", title: "Version", value: app.version ?? "1.0", color: .blue)
                    BentoInfoBox(icon: "shippingbox.fill", title: "Size", value: app.size ?? "N/A", color: .purple)
                    BentoInfoBox(icon: "folder.fill", title: "Category", value: app.category ?? "App", color: .orange)
                    BentoInfoBox(icon: "person.fill", title: "Developer", value: app.developer ?? "Unknown", color: .green)
                }
                .padding(.horizontal, 24)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.system(size: 20, weight: .bold))
                    
                    if let hacks = app.hack, !hacks.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(hacks, id: \.self) { hack in
                                HStack(alignment: .top, spacing: 10) {
                                    Text("•")
                                        .foregroundColor(.secondary)
                                    Text(hack)
                                        .font(.system(size: 15))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("Download \(app.name) securely from the AshteMobile repository. Enjoy fast performance and seamless updates.")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineSpacing(5)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
                .background(Color(UIColor.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationBarHidden(true)
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

struct BentoInfoBox: View {
    let icon: String; let title: String; let value: String; let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
        downloadTask = session?.downloadTask(with: url); downloadTask?.resume()
    }
    
    func stop() { downloadTask?.cancel(); isDownloading = false; progress = 0 }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 { DispatchQueue.main.async { self.progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite) } }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let dest = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".ipa")
        try? FileManager.default.copyItem(at: location, to: dest)
        DispatchQueue.main.async { self.isDownloading = false; self.isFinished = true; self.onFinished?(dest)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { self.isFinished = false } }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error != nil { DispatchQueue.main.async { self.isDownloading = false } }
        session.finishTasksAndInvalidate()
    }
}

struct HomeDownloadButtonView: View {
    let app: HomeApp; @ObservedObject var downloadManager: DownloadManager; var onDownloadComplete: () -> Void
    var isLarge: Bool = false
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        Group {
            if downloader.isFinished {
                Button(action: {}) {
                    Image(systemName: "checkmark")
                        .font(.system(size: isLarge ? 16 : 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLarge ? 12 : 7)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .disabled(true)
            } else if downloader.isDownloading {
                ZStack {
                    Circle().stroke(Color(UIColor.systemGray5), lineWidth: 3).frame(width: isLarge ? 36 : 28, height: isLarge ? 36 : 28)
                    if downloader.progress > 0 {
                        Circle().trim(from: 0, to: downloader.progress)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90)).frame(width: isLarge ? 36 : 28, height: isLarge ? 36 : 28)
                    }
                    RoundedRectangle(cornerRadius: 3).fill(Color.blue).frame(width: isLarge ? 12 : 10, height: isLarge ? 12 : 10)
                        .onTapGesture { downloader.stop() }
                }
                .frame(height: isLarge ? 44 : 30)
            } else {
                Button(action: {
                    if let url = URL(string: app.url) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        downloader.start(url: url) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            onDownloadComplete()
                        }
                    }
                }) {
                    Text("GET")
                        .font(.system(size: isLarge ? 15 : 13, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, isLarge ? 12 : 7)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }.frame(height: isLarge ? 44 : 30)
    }
}
