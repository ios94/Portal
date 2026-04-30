import SwiftUI
import NimbleViews
import Foundation
import UIKit

// MARK: - Data Model
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
            NBNavigationView("Explore") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        
                        // MARK: - Featured Hero Slider
                        if !featuredApps.isEmpty {
                            TabView {
                                ForEach(featuredApps) { app in
                                    NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                        showDownloadNotification(for: app)
                                    }) {
                                        FeaturedHeroCard(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .frame(height: 320)
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        }

                        // MARK: - Categories
                        VStack(alignment: .leading, spacing: 28) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Text(category)
                                            .font(.system(size: 22, weight: .bold, design: .rounded))
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 18) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    ModernAppCard(app: app, downloadManager: downloadManager) {
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
                            .padding(.bottom, 40)
                    }
                }
                .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
                .refreshable { await loadApps() }
            }
            .searchable(text: $searchText, prompt: "Search apps...")
            .onAppear { Task { await loadApps() } }
            
            // Notification
            if showNotification, let app = downloadedApp {
                notificationBanner(for: app)
                    .padding(.top, 50)
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
            withAnimation(.easeOut) { self.showNotification = false }
        }
    }

    @ViewBuilder
    private func notificationBanner(for app: HomeApp) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: { Color.blue }
            .frame(width: 45, height: 45)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Download Complete")
                    .font(.system(size: 14, weight: .bold))
                Text("\(app.name) is ready in Library.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .padding(.horizontal)
        .transition(.move(edge: .top).combined(with: .opacity))
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

// MARK: - Components
struct FeaturedHeroCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: app.fullBannerURL) { image in
                image.resizable().scaledToFill()
            } placeholder: { Color.blue.opacity(0.1) }
            .frame(width: UIScreen.main.bounds.width - 40, height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.status?.uppercased() ?? "NEW")
                            .font(.system(size: 10, weight: .black))
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Color.white).foregroundColor(.blue).clipShape(Capsule())
                        
                        Text(app.name).font(.title2.bold()).foregroundColor(.white)
                    }
                    Spacer()
                    HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                        .background(Circle().fill(.ultraThinMaterial))
                }
            }
            .padding(25)
            .background(LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        }
    }
}

struct ModernAppCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().scaledToFill()
            } placeholder: { Color.gray.opacity(0.1) }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            
            Text(app.name).font(.system(size: 14, weight: .bold)).lineLimit(1)
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .frame(width: 120)
    }
}
