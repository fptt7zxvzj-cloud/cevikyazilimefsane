//
//  EventsListView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//

import SwiftUI

struct EventsListView: View {
    @StateObject private var vm = EventListViewModel()
    
    var body: some View {
        ZStack {
            // Arkaplan tasarımınla uyumlu
            LiquidBackground()
            
            // Yükleniyor durumu
            if vm.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.blue)
            }
            // KABUL KRİTERİ 3: Boş Liste Durumu
            else if vm.events.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary.opacity(0.5))
                        .symbolEffect(.bounce, value: vm.isLoading) // iOS 17+ animasyon
                    
                    Text("Henüz görüntülenecek bir etkinlik bulunmamaktadır")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            // KABUL KRİTERİ 2: Etkinlik Listesi
            else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 20) {
                        ForEach(vm.events) { event in
                            // --- DEĞİŞİKLİK BURADA BAŞLIYOR ---
                            NavigationLink(destination: EventDetailView(event: event)) {
                                EventRowCard(event: event)
                            }
                            .buttonStyle(.plain) // Kartın maviye boyanmasını engeller
                            // --- DEĞİŞİKLİK BURADA BİTİYOR ---
                        }
                    }
                    .padding(20)
                }
                .refreshable {
                    // Listeyi aşağı çekince yenileme özelliği
                    await vm.loadEvents()
                }
            }
        }
        .onAppear {
            // Sayfa açıldığında verileri çek
            Task { await vm.loadEvents() }
        }
    }
}

// MARK: - Event Row Card (Component)
struct EventRowCard: View {
    let event: Event
    
    var body: some View {
        GlassCard {
            HStack(spacing: 16) {
                // Sol Taraf: Tarih Kutusu
                VStack(spacing: 2) {
                    Text(event.monthString)
                        .font(.caption.bold())
                        .foregroundStyle(.red.opacity(0.8))
                    
                    Text(event.dayString)
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                }
                .frame(width: 60, height: 65)
                .background(Color.white.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.05), radius: 5)
                
                // Sağ Taraf: Detaylar
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    if let clubName = event.clubName {
                        Text(clubName)
                            .font(.caption2.bold())
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 12) {
                        Label(event.timeString, systemImage: "clock")
                        Label(event.location, systemImage: "mappin.and.ellipse")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Detay ikonu (opsiyonel)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary.opacity(0.4))
            }
        }
    }
}

#Preview {
    EventsListView()
}
