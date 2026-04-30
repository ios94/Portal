//
//  HomeView.swift (CLEAN MODERN UI)
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - MODEL

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

// MARK: - HOME VIEW

struct HomeView: View {
    @StateObject var downloadManager = DownloadManager.shared
    @State private var apps: [HomeApp] = []
    
    @State private var showNotification = false
    @State private var downloadedApp: HomeApp? = nil
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(3))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            
            // CLEAN BACKGROUND
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            NBNavigationView("Home") {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // FEATURED
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        FeaturedAppView(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 220)
                            .tabViewStyle(.page)
                        }
                        
                        // CATEGORIES
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 12) {
                                    
                                    Text(category)
                                        .font(.title3.weight(.semibold))
                                        .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 12) {
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
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                    }
                    .padding(.top, 10)
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
                    .padding(.top, 8)
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            self.showNotification = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut) {
                self.showNotification = false
            }
        }
    }
    
    private func notificationBanner(for app: HomeApp) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Downloaded")
                    .font(.subheadline.weight(.semibold))
                Text(app.name)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
        )
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async {
                self.apps = decoded
            }
        } catch {
            print(error)
        }
    }
}

// MARK: - FEATURED

struct FeaturedAppView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            LinearGradient(colors: [.clear, .black.opacity(0.6)],
                           startPoint: .top,
                           endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    
                    Text(app.category ?? "")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                    .colorScheme(.dark)
            }
            .padding()
        }
        .padding(.horizontal)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.05))
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

// MARK: - CARD

struct HomeAppCardView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: app.fullImageURL) { img in
                img.resizable()
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            Text(app.name)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(1)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .padding(12)
        .frame(width: 120, height: 170)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.04))
        )
    }
}

// MARK: - DOWNLOAD BUTTON

struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    @StateObject private var downloader = HomeAppDownloader()
    
    var body: some View {
        ZStack {
            if downloader.isDownloading {
                ProgressView()
                    .scaleEffect(0.8)
            } else if downloader.isFinished {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
            } else {
                Button("GET") {
                    if let url = URL(string: app.url) {
                        downloader.start(url: url) { localURL in
                            _ = downloadManager.startDownload(from: localURL)
                            onDownloadComplete()
                        }
                    }
                }
                .font(.system(size: 12, weight: .bold))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Color(UIColor.systemGray5))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }
        }
        .frame(height: 28)
    }
}
