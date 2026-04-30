//
//  HomeView.swift
//  Feather
//

import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - App Model
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
    
    var featuredApps: [HomeApp] {
        Array(apps.filter { $0.status == "new" || $0.status == "top" || $0.status == "update" }.prefix(5))
    }
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            NBNavigationView("Discover") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        
                        // MARK: - Premium Hero Slider
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        ModernHeroCard(app: app)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 300)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                            .padding(.top, 15)
                        }
                        
                        // MARK: - Dynamic Categories
                        VStack(alignment: .leading, spacing: 25) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 18) {
                                    HStack(alignment: .bottom) {
                                        Text(category)
                                            .font(.system(size: 24, weight: .bold, design: .rounded))
                                        Spacer()
                                        Text("View All")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.blue)
                                    }
                                    .padding(.horizontal, 22)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 18) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    PremiumGridCard(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 22)
                                    }
                                }
                            }
                        }
                        
                        SocialMediaFooter()
                            .padding(.bottom, 100)
                    }
                }
                .refreshable { await loadApps() }
            }
            .onAppear { Task { await loadApps() } }
            
            // Floating Notification Toast
            if showNotification, let app = downloadedApp {
                DownloadSuccessToast(app: app)
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation { self.showNotification = false }
        }
    }
    
    private func loadApps() async {
        guard let url = URL(string: "https://ashtemobile.tututweak.com/ipa.json") else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode([HomeApp].self, from: data)
            DispatchQueue.main.async { self.apps = decoded }
        } catch { print("Fetch Error: \(error)") }
    }
}

// MARK: - UI Elements (Hero Card)
struct ModernHeroCard: View {
    let app: HomeApp
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.blue.opacity(0.1) }
            .frame(width: UIScreen.main.bounds.width - 44, height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            
            LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(app.status?.uppercased() ?? "PREMIUM")
                    .font(.caption2.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                
                Text(app.name)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                
                Text(app.category ?? "Application")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(30)
        }
        .padding(.horizontal, 22)
        .shadow(color: Color.black.opacity(0.15), radius: 15, y: 10)
    }
}

// MARK: - UI Elements (App Card)
struct PremiumGridCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void 
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.gray.opacity(0.1) }
            .frame(width: 90, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
            
            VStack(spacing: 4) {
                Text(app.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(app.category ?? "App")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 5, y: 2)
        )
        .frame(width: 140)
    }
}

// MARK: - Notification Toast
struct DownloadSuccessToast: View {
    let app: HomeApp
    var body: some View {
        HStack(spacing: 15) {
            AsyncImage(url: app.fullImageURL).frame(width: 38, height: 38).clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text("Ready to Install").font(.subheadline.bold())
                Text(app.name).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green).font(.title3)
        }
        .padding()
        .background(BlurView(style: .systemUltraThinMaterial))
        .clipShape(Capsule())
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// (تێبینی: پێکهاتەکانی تری وەک HomeAppDetailView و HomeDownloadButtonView وەک خۆیان دەمێننەوە تەنها ستایلەکەیان لەگەڵ ئەم نوێیە ڕێک خراوە)
