//
//  HomeView.swift (MODERN UI)
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
    
    var groupedApps: [(String, [HomeApp])] {
        let dict = Dictionary(grouping: apps, by: { $0.category ?? "Apps" })
        return dict.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack {
            
            // 🌈 Background Gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.15),
                    Color(UIColor.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            NBNavigationView("Home") {
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // 🔥 Featured
                        TabView {
                            ForEach(apps.prefix(5)) { app in
                                FeaturedAppView(app: app, downloadManager: downloadManager)
                            }
                        }
                        .frame(height: 240)
                        .tabViewStyle(.page)
                        
                        // 📦 Categories
                        ForEach(groupedApps, id: \.0) { category, categoryApps in
                            VStack(alignment: .leading, spacing: 15) {
                                
                                Text(category)
                                    .font(.title2.bold())
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(categoryApps) { app in
                                            HomeAppCardView(app: app, downloadManager: downloadManager)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.top)
                }
                .refreshable {
                    await loadApps()
                }
            }
            .onAppear {
                Task { await loadApps() }
            }
        }
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
            print("Error: \(error)")
        }
    }
}

// MARK: - FEATURED CARD

struct FeaturedAppView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            AsyncImage(url: app.fullBannerURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            
            LinearGradient(colors: [.clear, .black.opacity(0.8)],
                           startPoint: .top,
                           endPoint: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            
            HStack {
                VStack(alignment: .leading) {
                    Text(app.name)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(app.category ?? "App")
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HomeDownloadButtonView(app: app, downloadManager: downloadManager)
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

// MARK: - APP CARD

struct HomeAppCardView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    @State private var press = false
    
    var body: some View {
        VStack(spacing: 8) {
            
            AsyncImage(url: app.fullImageURL) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Text(app.name)
                .font(.system(size: 14, weight: .bold))
                .lineLimit(1)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager)
        }
        .padding()
        .frame(width: 130)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
        .scaleEffect(press ? 0.95 : 1)
        .onTapGesture {
            withAnimation(.spring()) {
                press.toggle()
            }
        }
    }
}

// MARK: - DOWNLOAD BUTTON

struct HomeDownloadButtonView: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    
    var body: some View {
        Button("Get") {
            if let url = URL(string: app.url) {
                downloadManager.startDownload(from: url)
            }
        }
        .font(.system(size: 13, weight: .bold))
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundColor(.white)
        .clipShape(Capsule())
        .shadow(color: .blue.opacity(0.4), radius: 6)
    }
}
