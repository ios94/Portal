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
}

// MARK: - Main Home View (Neumorphic Soft UI)
struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" }.prefix(5))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Collection" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack {
            // Background Color (Neumorphic Gray)
            Color(hex: "F0F2F5").ignoresSafeArea()
            
            NBNavigationView("Ashte Store") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 40) {
                        
                        // MARK: - Modern Hero Slider
                        if !featuredApps.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 25) {
                                    ForEach(featuredApps) { app in
                                        NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }) {
                                            NeumorphicHeroCard(app: app)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 25)
                                .padding(.vertical, 10)
                            }
                        }
                        
                        // MARK: - App Rows
                        VStack(alignment: .leading, spacing: 30) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 15) {
                                    Text(category)
                                        .font(.system(size: 22, weight: .black, design: .rounded))
                                        .foregroundColor(Color.gray)
                                        .padding(.horizontal, 30)
                                    
                                    ForEach(categoryApps) { app in
                                        NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }) {
                                            NeumorphicRow(app: app, downloadManager: downloadManager) {
                                                showDownloadNotification(for: app)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        
                        Spacer().frame(height: 100)
                    }
                }
                .refreshable { await loadApps() }
            }
            .onAppear { Task { await loadApps() } }
            
            if showNotification, let app = downloadedApp {
                DownloadSuccessToast(app: app)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring()) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { self.showNotification = false }
        }
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            await MainActor.run { self.apps = decoded }
        } catch { print("Error") }
    }
}

// MARK: - Neumorphic Components

struct NeumorphicHeroCard: View {
    let app: HomeApp
    var body: some View {
        VStack(spacing: 15) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.white.opacity(0.1) }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 5, y: 5)
            .shadow(color: Color.white.opacity(0.8), radius: 10, x: -5, y: -5)
            
            Text(app.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.darkText)
        }
        .frame(width: 180, height: 220)
        .background(Color(hex: "F0F2F5"))
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 10, y: 10)
        .shadow(color: Color.white.opacity(0.9), radius: 15, x: -10, y: -10)
    }
}

struct NeumorphicRow: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            AsyncImage(url: app.fullImageURL)
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 15))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 3, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.system(size: 17, weight: .bold))
                Text(app.developer ?? "Ashte Store").font(.system(size: 13)).foregroundColor(.secondary)
            }
            
            Spacer()
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                .frame(width: 70)
        }
        .padding(15)
        .background(Color(hex: "F0F2F5"))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 5, y: 5)
        .shadow(color: Color.white.opacity(0.8), radius: 10, x: -5, y: -5)
        .padding(.horizontal, 25)
    }
}

struct DownloadSuccessToast: View {
    let app: HomeApp
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "checkmark.seal.fill").foregroundColor(.blue)
                Text("\(app.name) Added").font(.headline)
            }
            .padding()
            .background(Color.white)
            .clipShape(Capsule())
            .shadow(radius: 10)
            .padding(.top, 50)
            Spacer()
        }
    }
}

// MARK: - Detail View
struct HomeAppDetailView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color(hex: "F0F2F5").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    HStack {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left").font(.title3).foregroundColor(.darkText)
                                .padding().background(Color(hex: "F0F2F5")).clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 3, y: 3)
                        }
                        Spacer()
                    }.padding(.horizontal, 25)
                    
                    VStack(spacing: 20) {
                        AsyncImage(url: app.fullImageURL)
                            .frame(width: 140, height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 35))
                            .shadow(color: Color.black.opacity(0.1), radius: 15, x: 10, y: 10)
                            .shadow(color: Color.white.opacity(0.9), radius: 15, x: -10, y: -10)
                        
                        Text(app.name).font(.system(size: 28, weight: .black))
                        Text(app.developer ?? "Official App").foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 20) {
                        InfoLabel(t: "Version", v: app.version ?? "1.0")
                        InfoLabel(t: "Size", v: app.size ?? "N/A")
                        
                        Text("Features").font(.headline).padding(.top)
                        Text(app.hack?.joined(separator: "\n") ?? "Standard version with full support.")
                            .foregroundColor(.secondary).lineSpacing(8)
                        
                        HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                            .frame(height: 55).padding(.top)
                    }
                    .padding(30)
                    .background(Color(hex: "F0F2F5"))
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                    .shadow(color: Color.black.opacity(0.05), radius: 20, x: 10, y: 10)
                    .padding(.horizontal, 25)
                }
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
    }
}

struct InfoLabel: View {
    let t: String; let v: String
    var body: some View {
        HStack {
            Text(t).foregroundColor(.secondary)
            Spacer()
            Text(v).bold()
        }
        .padding().background(Color.white.opacity(0.5)).clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

// MARK: - Helpers
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
    static let darkText = Color(white: 0.2)
}

struct HomeDownloadButtonView: View {
    let app: HomeApp; @ObservedObject var downloadManager: DownloadManager; var onDownloadComplete: () -> Void
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        Button(action: {
            if let url = URL(string: app.url) {
                downloader.start(url: url) { local in
                    _ = downloadManager.startDownload(from: local)
                    onDownloadComplete()
                }
            }
        }) {
            ZStack {
                if downloader.isDownloading {
                    Circle().trim(from: 0, to: downloader.progress).stroke(Color.blue, lineWidth: 3).rotationEffect(.degrees(-90))
                } else {
                    Text(downloader.isFinished ? "OPEN" : "GET")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: "F0F2F5"))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 3, y: 3)
            .shadow(color: Color.white.opacity(0.9), radius: 5, x: -3, y: -3)
        }
        .frame(height: 35)
    }
}

class HomeAppDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    @Published var progress: CGFloat = 0
    @Published var isDownloading = false
    @Published var isFinished = false
    
    func start(url: URL, completion: @escaping (URL) -> Void) {
        self.isDownloading = true
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        session.downloadTask(with: url).resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        progress = CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async { self.isDownloading = false; self.isFinished = true }
    }
}
