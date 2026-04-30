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

// MARK: - Main Home View (Dynamic Mesh Style)
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
            // MARK: - Dynamic Mesh Background
            MeshGradientView().ignoresSafeArea()
            
            NBNavigationView("Ashte") {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 35) {
                        
                        // MARK: - Liquid Featured Slider
                        if !featuredApps.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(featuredApps) { app in
                                        NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                            showDownloadNotification(for: app)
                                        }) {
                                            LiquidHeroCard(app: app)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // MARK: - Glass Sections
                        VStack(alignment: .leading, spacing: 25) {
                            ForEach(groupedApps, id: \.0) { category, categoryApps in
                                VStack(alignment: .leading, spacing: 15) {
                                    Text(category)
                                        .font(.system(size: 20, weight: .black, design: .rounded))
                                        .padding(.horizontal, 25)
                                        .foregroundColor(.primary.opacity(0.8))
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 18) {
                                            ForEach(categoryApps) { app in
                                                NavigationLink(destination: HomeAppDetailView(app: app, downloadManager: downloadManager) {
                                                    showDownloadNotification(for: app)
                                                }) {
                                                    GlassAppCard(app: app, downloadManager: downloadManager) {
                                                        showDownloadNotification(for: app)
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal, 25)
                                    }
                                }
                            }
                        }
                        
                        Spacer().frame(height: 80)
                    }
                }
                .refreshable { await loadApps() }
            }
            .onAppear { Task { await loadApps() } }
            
            if showNotification, let app = downloadedApp {
                GlassNotification(app: app)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
            }
        }
    }
    
    private func showDownloadNotification(for app: HomeApp) {
        self.downloadedApp = app
        withAnimation(.spring()) { self.showNotification = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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

// MARK: - Modern Components

struct MeshGradientView: View {
    var body: some View {
        ZStack {
            Color.white
            LinearGradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.blue.opacity(0.05)).frame(width: 400).offset(x: -150, y: -200).blur(radius: 80)
            Circle().fill(Color.purple.opacity(0.05)).frame(width: 300).offset(x: 150, y: 300).blur(radius: 80)
        }
    }
}

struct LiquidHeroCard: View {
    let app: HomeApp
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: app.fullImageURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: { Color.gray.opacity(0.1) }
            .frame(width: 300, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            
            VisualEffectBlur(blurStyle: .systemUltraThinMaterialDark)
                .frame(height: 60)
                .clipShape(RoundedCorner(radius: 30, corners: [.bottomLeft, .bottomRight]))
            
            Text(app.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 20).padding(.bottom, 18)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 15, y: 10)
    }
}

struct GlassAppCard: View {
    let app: HomeApp
    @ObservedObject var downloadManager: DownloadManager
    var onDownloadComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: app.fullImageURL)
                .frame(width: 85, height: 85)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
            
            Text(app.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
            
            HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
        }
        .padding(15)
        .background(Color.white.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.5), lineWidth: 1))
        .frame(width: 120)
    }
}

struct GlassNotification: View {
    let app: HomeApp
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                Text("\(app.name) Downloaded").font(.system(size: 14, weight: .bold))
            }
            .padding().background(.ultraThinMaterial).clipShape(Capsule()).shadow(radius: 10)
            .padding(.bottom, 40)
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
        ScrollView {
            VStack(spacing: 30) {
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: app.fullImageURL)
                        .frame(maxWidth: .infinity).frame(height: 300).clipped().blur(radius: 40).opacity(0.3)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        Button(action: { presentationMode.wrappedValue.dismiss() }) {
                            Image(systemName: "chevron.left").font(.title3).padding().background(.white).clipShape(Circle())
                        }
                        
                        HStack(spacing: 20) {
                            AsyncImage(url: app.fullImageURL).frame(width: 110, height: 110).clipShape(RoundedRectangle(cornerRadius: 25))
                            VStack(alignment: .leading, spacing: 5) {
                                Text(app.name).font(.system(size: 26, weight: .heavy))
                                Text(app.developer ?? "Ashte Store").foregroundColor(.secondary)
                            }
                        }
                    }.padding(30)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("About").font(.title3.bold())
                    Text("Version: \(app.version ?? "1.0")").padding(.horizontal).padding(.vertical, 8).background(Color.blue.opacity(0.05)).clipShape(Capsule())
                    
                    Text(app.hack?.joined(separator: "\n") ?? "Enjoy the premium features.")
                        .foregroundColor(.secondary).lineSpacing(6)
                    
                    HomeDownloadButtonView(app: app, downloadManager: downloadManager, onDownloadComplete: onDownloadComplete)
                        .frame(height: 50).padding(.top)
                }
                .padding(30)
                .background(Color.white).cornerRadius(40, corners: [.topLeft, .topRight])
                .offset(y: -40)
            }
        }
        .ignoresSafeArea().navigationBarHidden(true)
    }
}

// MARK: - Logic Helpers
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView(effect: UIBlurEffect(style: blurStyle)) }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = UIBlurEffect(style: blurStyle) }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
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
            if downloader.isDownloading {
                ProgressView(value: downloader.progress).tint(.blue).frame(height: 4)
            } else {
                Text(downloader.isFinished ? "OPEN" : "GET")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .clipShape(Capsule())
            }
        }.frame(height: 32)
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
