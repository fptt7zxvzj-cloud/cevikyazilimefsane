//
//  MainMenuView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 26.11.2025.
//

import SwiftUI
import Combine

struct MainMenuView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedTab: Int = 0
    
    // YENİ STATE'LER
    @State private var showCreateClubView = false // Sayfaya gitmek için
    @State private var showPermissionAlert = false // Uyarı göstermek için
    
    init() {
        // ... (Senin mevcut init kodların aynı kalsın) ...
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // TAB 1: KULÜPLER
            NavigationStack {
                ClubsListView()
                    .navigationTitle("Kulüpler")
                    .toolbar {
                        // Profil butonu (Sol)
                        // Profil butonuna basınca (MainMenuView):
                        ToolbarItem(placement: .topBarLeading) {
                            Menu {
                                if session.userProfile?.role == "admin" {
                                    NavigationLink(destination: AdminUserListView()) {
                                        Label("Kullanıcı Yönetimi", systemImage: "shield.fill")
                                    }
                                }
                                Button("Çıkış Yap") {
                                    try? session.signOut()
                                }
                            } label: {
                                Image(systemName: "person.circle")
                                   // ...
                            }
                        }
                        
                        // + Butonu (Sağ) - Kulüp Oluştur
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                // KABUL KRİTERİ 3: Yetki Kontrolü Güncellemesi
                                let role = session.userProfile?.role ?? "user"
                                
                                // Hem 'admin' hem de 'club_manager' kulüp oluşturabilir
                                if role == "admin" || role == "club_manager" {
                                    showCreateClubView = true
                                } else {
                                    showPermissionAlert = true
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    // ... (Tasarım kodların aynı kalabilir) ...
                            }
                        }
                    }
                    // Programatik Navigasyon (Eğer admin ise çalışır)
                    .navigationDestination(isPresented: $showCreateClubView) {
                        CreateClubView()
                    }
                    // Yetki Uyarısı
                    .alert("Yetkisiz İşlem", isPresented: $showPermissionAlert) {
                        Button("Tamam", role: .cancel) { }
                    } message: {
                        Text("Kulüp oluşturmak için yönetici (admin) yetkisine sahip olmanız gerekmektedir.")
                    }
            }
            .tabItem {
                Label("Kulüpler", systemImage: "person.3.sequence.fill")
            }
            .tag(0)
            
            // TAB 2: ETKİNLİKLER
            NavigationStack {
                EventsListView()
                    .navigationTitle("Etkinlikler")
            }
            .tabItem {
                Label("Etkinlikler", systemImage: "calendar.badge.clock")
            }
            .tag(1)
        }
        .tint(.blue)
    }
}

// MARK: - Subviews for Tabs

struct ClubsListView: View {
    // Gerçek veri bağlantısı için burada onAppear ile fetch yapabilirsin
    // Şimdilik tasarım odaklı sahte veri veya boş state
    @StateObject private var vm = ClubListViewModel() // Aşağıda basit bir VM tanımlayalım
    
    var body: some View {
        ZStack {
            LiquidBackground() // Ortak arkaplan
            
            if vm.clubs.isEmpty && vm.isLoading {
                ProgressView()
            } else if vm.clubs.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.sequence")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Henüz kulüp yok.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        ForEach(vm.clubs) { club in
                            NavigationLink(destination: ClubDetailView(club: club)) {
                                ClubRowCard(club: club)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            Task { await vm.loadClubs() }
        }
    }
}

// MARK: - Club Row Card Component (Güncellendi: Resim Gösteriyor)
struct ClubRowCard: View {
    let club: Club
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Logo
                if let urlString = club.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else if phase.error != nil {
                            PlaceholderLogo(name: club.name)
                        } else {
                            ProgressView()
                                .frame(width: 60, height: 60)
                        }
                    }
                } else {
                    PlaceholderLogo(name: club.name)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.name)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text(club.category)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(Color.blue)
                        .clipShape(Capsule())
                    
                    Text(club.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
    }
}

// Resim yoksa gösterilecek varsayılan logo
struct PlaceholderLogo: View {
    let name: String
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.blue.opacity(0.2), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 60)
            
            Text(String(name.prefix(1)))
                .font(.title2.bold())
                .foregroundStyle(.primary.opacity(0.7))
        }
    }
}

// MARK: - Simple ViewModel for List
class ClubListViewModel: ObservableObject {
    @Published var clubs: [Club] = []
    @Published var isLoading = false
    private let manager = ClubManager()
    
    @MainActor
    func loadClubs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            clubs = try await manager.fetchClubs()
        } catch {
            print("Hata: \(error.localizedDescription)")
        }
    }
}
