//
//  ClubDetailView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 26.11.2025.
//

import SwiftUI
import Combine

@MainActor
class ClubDetailViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    
    // YENİ STATE'LER
    @Published var members: [UserProfile] = [] // Üyelerin detaylı bilgileri
    @Published var isJoining = false // Buton dönme efekti için
    @Published var isLoadingMembers = false // Üye listesi yükleniyor mu?

    private let manager = EventManager()
    private let clubManager = ClubManager.shared
    
    
    // Sadece bu kulübün etkinliklerini çek
    func getClubEvents(clubId: String) async {
        isLoading = true
        do {
            // EventManager'a eklediğimiz fonksiyonu kullanıyoruz
            let fetchedEvents = try await manager.fetchEvents(for: clubId)
            self.events = fetchedEvents
        } catch {
            print("Kulüp etkinlikleri çekilemedi: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    // KULÜBE KATIL
    func joinClub(clubId: String, userId: String) async {
        isJoining = true
        do {
            try await clubManager.joinClub(clubId: clubId, userId: userId)
            // Başarılı olursa UI'ı güncellemek için üyeleri tekrar çekebilirsin
            // veya basitçe sayfayı yenilemek gerekebilir.
            print("Kulübe katılındı!")
        } catch {
            print("Katılma hatası: \(error.localizedDescription)")
        }
        isJoining = false
    }
    
    // ÜYELERİ YÜKLE
    func loadMemberProfiles(memberIds: [String]) async {
        guard !memberIds.isEmpty else { return }
        isLoadingMembers = true
        do {
            self.members = try await clubManager.fetchMembersProfiles(memberIds: memberIds)
        } catch {
            print("Üyeler çekilemedi: \(error.localizedDescription)")
        }
        isLoadingMembers = false
    }
    
    // KULÜPTEN AYRIL
    func leaveClub(clubId: String, userId: String) async {
        isJoining = true // Yükleniyor efekti için aynı değişkeni kullanabiliriz
        do {
            try await clubManager.leaveClub(clubId: clubId, userId: userId)
            print("Kulüpten ayrılındı.")
        } catch {
            print("Ayrılma hatası: \(error.localizedDescription)")
        }
        isJoining = false
    }
}

struct ClubDetailView: View {
    let club: Club
    
    // Tab Kontrolü için State (0: Bilgiler, 1: Etkinlikler)
    @State private var selectedTab: Int = 0
    @Namespace private var animation // Tab geçiş animasyonu için
    
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var session: AppSession // YENİ: Yetki kontrolü için
    @State private var showCreateEvent = false // YENİ: Modal kontrolü
    @StateObject private var vm = ClubDetailViewModel()
    var canCreateEvent: Bool {
        guard let user = session.userProfile else { return false }
        // 1. Kullanıcı Admin mi?
        if user.role == "club_manager" { return true }
        // 2. Kullanıcı bu kulübün yöneticisi mi? (createdBy == uid)
        // VEYA Kullanıcı genel "club_manager" rolüne sahip mi? (Tercihine göre)
        // Burada basitlik adına "Kulübü oluşturan kişi veya admin" diyoruz:
        return club.createdBy == user.uid
    }
    
    @State private var dynamicMemberIds: [String] = [] // YENİ: Anlık değişim için
    
    var body: some View {
        ZStack {
            // 1. Arka Plan
            LiquidBackground()
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // 2. Üst Header (Logo ve İsim - Sabit kalacak)
                        headerSection
                            .padding(.top, 20)
                        
                        // 3. SEGMENTED CONTROL (Geçiş Butonları)
                        customTabSwitcher
                        
                        // 4. DEĞİŞEN İÇERİK ALANI
                        if selectedTab == 0 {
                            // --- BİLGİLER TABI ---
                            VStack(spacing: 20) {
                                statsSection
                                infoCardsSection
                                if !dynamicMemberIds.isEmpty {
                                    MembersListSection(memberIds: dynamicMemberIds, vm: vm)
                                }
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                            
                        } else {
                            // --- ETKİNLİKLER TABI ---
                            eventsListSection
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        
                        // Alt boşluk (Buton için)
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal)
                }
            }
            
            // 5. Alt Aksiyon Butonu (Sticky)
            VStack {
                Spacer()
                actionButtonSection
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // Animasyonların düzgün çalışması için
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedTab)
        .onAppear {
            // Kulüpten gelen mevcut üyeleri state'e atıyoruz
            dynamicMemberIds = club.members
            Task {
                await vm.getClubEvents(clubId: club.safeId)
            }
        }
        .onChange(of: showCreateEvent) { newValue in
            if !newValue { // Modal kapandıysa
                Task { await vm.getClubEvents(clubId: club.safeId) }
            }
        }
    }
}

// MARK: - Üyeler Bölümü (Açılır/Kapanır)
struct MembersListSection: View {
    let memberIds: [String]
    @ObservedObject var vm: ClubDetailViewModel
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Açılır/Kapanır Başlık Butonu
            Button {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
                // Açıldığında ve liste boşsa verileri çek
                if isExpanded && vm.members.isEmpty {
                    Task { await vm.loadMemberProfiles(memberIds: memberIds) }
                }
            } label: {
                HStack {
                    Label("Kulüp Üyeleri (\(memberIds.count))", systemImage: "person.2.crop.square.stack")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
            
            // Liste İçeriği (Sadece isExpanded ise görünür)
            if isExpanded {
                if vm.isLoadingMembers {
                    ProgressView().padding()
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.members) { member in
                            HStack {
                                // Profil Resmi (Basit Avatar)
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                    .overlay(Text(member.displayName.prefix(1)).bold().foregroundStyle(.blue))
                                
                                VStack(alignment: .leading) {
                                    Text(member.displayName)
                                        .font(.subheadline.bold())
                                    Text(member.role) // veya "Üye"
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal)
                            Divider().padding(.leading, 56)
                        }
                    }
                    .padding(.vertical)
                    .background(.white.opacity(0.3)) // Liste arkaplanı
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Subviews & Components
extension ClubDetailView {
    
    // MARK: Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Logo
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 130, height: 130)
                    .background(
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .blur(radius: 20)
                            .opacity(0.6)
                    )
                
                if let urlString = club.imageUrl, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 2))
                        } else {
                            ProgressView()
                        }
                    }
                } else {
                    Text(String(club.name.prefix(1)))
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 120, height: 120)
                        .background(Color.blue.opacity(0.3))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.5), lineWidth: 2))
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            // İsim ve Kategori
            VStack(spacing: 8) {
                Text(club.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text(club.category)
                    .font(.callout.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .foregroundStyle(.blue)
            }
        }
    }
    
    // MARK: Custom Tab Switcher
    private var customTabSwitcher: some View {
        HStack(spacing: 0) {
            // Tab 1: Bilgiler
            tabButton(title: "Bilgiler", icon: "info.circle", index: 0)
            
            // Tab 2: Etkinlikler
            tabButton(title: "Etkinlikler", icon: "calendar", index: 1)
        }
        .padding(4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.3), lineWidth: 1))
        .padding(.vertical, 10)
    }
    
    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            selectedTab = index
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .foregroundColor(selectedTab == index ? .white : .secondary)
            .background {
                if selectedTab == index {
                    Capsule()
                        .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                        .matchedGeometryEffect(id: "activeTab", in: animation)
                        .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - CONTENT: INFO TAB
    private var statsSection: some View {
        HStack(spacing: 20) {
            StatItem(icon: "person.2.fill", value: "\(club.memberCount)", title: "Üye")
            Divider().frame(height: 30).background(Color.primary.opacity(0.2))
            StatItem(icon: "calendar", value: formatDate(club.createdAt), title: "Kuruluş")
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - CONTENT: EVENTS TAB
    private var eventsListSection: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // Eğer yükleniyorsa
            if vm.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 200)
            }
            // Eğer hiç etkinlik yoksa
            else if vm.events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("Bu kulübe ait henüz planlanmış bir etkinlik yok.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            }
            // Eğer etkinlik varsa LİSTELE
            else {
                VStack(spacing: 16) {
                    ForEach(vm.events) { event in
                        // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
                        NavigationLink(destination: EventDetailView(event: event)) {
                            EventRowCard(event: event)
                        }
                        .buttonStyle(.plain) // Kartın maviye boyanmasını engeller
                        // --- DEĞİŞİKLİK BURADA BİTİYOR ---
                    }
                }
                .padding(.bottom, 80) // Butonun altında kalmasın diye boşluk
            }
            
            // + Butonu
            if canCreateEvent {
                Button {
                    showCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.blue)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.bottom, 0) // ZStack içinde konumlandırma
            }
        }
        .sheet(isPresented: $showCreateEvent) {
            CreateEventView(
                clubId: club.safeId,
                clubName: club.name
            )
        }
    }
    
    private var infoCardsSection: some View {
        VStack(spacing: 20) {
            // Hakkında
            GlassCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Hakkında", systemImage: "doc.text.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(club.description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Vizyon
            if !club.vision.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Vizyonumuz", systemImage: "sparkles")
                            .font(.headline)
                            .foregroundStyle(.purple)
                        Text(club.vision)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Kurallar
            if !club.rules.isEmpty {
                GlassCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Kulüp Kuralları", systemImage: "list.bullet.rectangle.portrait.fill")
                            .font(.headline)
                            .foregroundStyle(.orange)
                        Text(club.rules)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // İletişim
            if let email = club.contactEmail, !email.isEmpty {
                GlassCard {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.blue)
                        Text("İletişim:")
                            .bold()
                        Spacer()
                        Text(email)
                            .tint(.blue)
                            .textSelection(.enabled)
                    }
                }
            }
        }
    }
    
    // MARK: Action Button
    private var actionButtonSection: some View {
        let currentUid = session.currentUser?.uid ?? ""
        // Durumu dynamicMemberIds üzerinden kontrol et
        let isMember = dynamicMemberIds.contains(currentUid)
        
        return Button {
            Task {
                if isMember {
                    // --- 1. AYRILMA İŞLEMİ ---
                    await vm.leaveClub(clubId: club.safeId, userId: currentUid)
                    
                    // A) ID Listesinden sil (Buton rengi ve sayı için)
                    if let index = dynamicMemberIds.firstIndex(of: currentUid) {
                        dynamicMemberIds.remove(at: index)
                    }
                    
                    // B) Profil Listesinden sil (Açılır liste içeriği için)
                    // Animasyonlu silinmesi için withAnimation kullanabilirsin
                    withAnimation {
                        vm.members.removeAll { $0.uid == currentUid }
                    }
                    
                } else {
                    // --- 2. KATILMA İŞLEMİ ---
                    await vm.joinClub(clubId: club.safeId, userId: currentUid)
                    
                    // A) ID Listesine ekle (Buton rengi ve sayı için)
                    dynamicMemberIds.append(currentUid)
                    
                    // B) Profil Listesine ekle (Açılır liste içeriği için)
                    // Mevcut kullanıcının profilini Session'dan alıp listeye ekliyoruz
                    if let myProfile = session.userProfile {
                        withAnimation {
                            vm.members.append(myProfile)
                        }
                    }
                }
            }
        } label: {
            HStack {
                if vm.isJoining {
                    ProgressView().tint(.white)
                } else {
                    Text(isMember ? "Kulüpten Ayrıl" : "Kulübe Katıl")
                        .font(.headline.bold())
                    
                    Image(systemName: isMember ? "door.left.hand.open" : "arrow.right.circle.fill")
                        .font(.title2)
                }
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                isMember
                ? LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                : LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: (isMember ? Color.red : Color.blue).opacity(0.4),
                radius: 10, x: 0, y: 5
            )
        }
        .disabled(vm.isJoining)
        .padding(.horizontal, 20)
        .padding(.bottom, 10)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }
}

// MARK: - Models & Helpers

struct SimpleEvent: Identifiable {
    let id = UUID()
    let title: String
    let date: String
    let location: String
    let time: String
}

struct StatItem: View {
    let icon: String
    let value: String
    let title: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
            
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
