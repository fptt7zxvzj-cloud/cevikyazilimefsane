//
//  CreateEventView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//


import SwiftUI

struct CreateEventView: View {
    let clubId: String
    let clubName: String
    @Environment(\.dismiss) var dismiss
    
    // Form State
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var isLoading = false
    
    private let manager = EventManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                LiquidBackground()
                
                ScrollView {
                    VStack(spacing: 20) {
                        GlassTextField(title: "Etkinlik Başlığı", text: $title, icon: "text.format")
                        
                        GlassTextField(title: "Açıklama", text: $description, icon: "text.alignleft", isMultiLine: true)
                        
                        GlassTextField(title: "Konum / Yer", text: $location, icon: "mappin.and.ellipse")
                        
                        // Tarih Seçici (Custom Glass Style)
                        VStack(alignment: .leading) {
                            Text("Tarih ve Saat").font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
                            DatePicker("", selection: $date)
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        }
                        
                        Button {
                            Task { await saveEvent() }
                        } label: {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Etkinliği Yayınla").bold()
                            }
                        }
                        .buttonStyle(GreenCapsuleStyle(disabled: title.isEmpty || isLoading))
                        .disabled(title.isEmpty || isLoading)
                        .padding(.top)
                    }
                    .padding()
                }
            }
            .navigationTitle("Yeni Etkinlik")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
    
    func saveEvent() async {
        isLoading = true
        // Modeli oluşturuyoruz
        let newEvent = Event(
            clubId: clubId, // Kulüp ID'si otomatik atanıyor
            title: title,
            description: description,
            date: date,
            location: location,
            imageUrl: nil,
            clubName: clubName
        )
        
        do {
            try await manager.createEvent(newEvent)
            dismiss() // Başarılıysa kapat
        } catch {
            print("Hata: \(error.localizedDescription)")
            isLoading = false
        }
    }
}
