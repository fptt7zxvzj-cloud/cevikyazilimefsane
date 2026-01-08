//
//  EventDetailView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//


//
//  EventDetailView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.dismiss) var dismiss

    @State private var hostingClub: Club?
    @State private var isLoadingClub = false
    
    var body: some View {
        ZStack {
            // 1. Arka Plan
            LiquidBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // MARK: - Üst Kısım (Tarih ve Başlık)
                    // ... Burası senin kodunla AYNI kalacak ...
                    VStack(spacing: 16) {
                        // Tarih Rozeti...
                        VStack(spacing: 0) {
                            Text(event.monthString)
                                .font(.title3.bold())
                                .foregroundStyle(.red.opacity(0.9))
                                .textCase(.uppercase)
                            Text(event.dayString)
                                .font(.system(size: 50, weight: .bold))
                                .foregroundStyle(.primary)
                        }
                        .frame(width: 100, height: 110)
                        .background(.white.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        
                        // Başlık
                        Text(event.title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.primary)
                        
                        // NOT: Buradaki Text(clubName) kısmını kaldırabilirsin
                        // çünkü aşağıda büyük kart olarak göstereceğiz.
                        // Ya da kalabilir, tercih senin.
                    }
                    .padding(.top, 20)
                    
                    // MARK: - Detay Kartları
                    VStack(spacing: 16) {
                        
                        // YENİ: KULÜP KARTI BURAYA GELİYOR
                        if let club = hostingClub {
                            // Kulüp yüklendiyse kartı göster
                            NavigationLink(destination: ClubDetailView(club: club)) {
                                ClubSummaryCard(club: club)
                            }
                            .buttonStyle(.plain)
                        } else if isLoadingClub {
                            // Yükleniyorsa loading göster
                            ProgressView()
                                .padding()
                        }
                        
                        // Zaman ve Konum Kartı (Senin kodun)
                        GlassCard {
                            VStack(spacing: 16) {
                                InfoRow(icon: "clock.fill", title: "Saat", value: event.timeString)
                                Divider()
                                InfoRow(icon: "mappin.and.ellipse", title: "Konum", value: event.location)
                            }
                        }
                        
                        // Açıklama Kartı (Senin kodun)
                        GlassCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Etkinlik Detayları", systemImage: "text.alignleft")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(event.description)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.horizontal)
                    
                    Color.clear.frame(height: 50)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        // YENİ: Sayfa açılınca kulüp detayını çek
        .task {
            await loadClubDetails()
        }
    }
    
    // Kulüp detayını çeken fonksiyon
    func loadClubDetails() async {
        isLoadingClub = true
        do {
            // ClubManager.shared.fetchClub senin yazdığın kulüp çekme fonksiyonun olmalı
            if let club = try await ClubManager.shared.fetchClub(id: event.clubId) {
                self.hostingClub = club
            }
        } catch {
            print("Kulüp detayı çekilemedi: \(error.localizedDescription)")
        }
        isLoadingClub = false
    }
}

// Detay satırı için yardımcı görünüm
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }
}

struct ClubSummaryCard: View {
    let club: Club
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Kulüp Logosu
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Etkinlik Sahibi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(club.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    // DÜZELTME BURADA:
                    // if let yerine .isEmpty kontrolü yapıyoruz veya direkt yazdırıyoruz
                    if !club.description.isEmpty {
                        Text(club.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Sağ ok ikonu
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary.opacity(0.5))
            }
        }
    }
}
