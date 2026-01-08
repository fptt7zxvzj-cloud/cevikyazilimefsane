//
//  CreateClubView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 26.11.2025.
//

import SwiftUI
import PhotosUI

struct CreateClubView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: AppSession
    @StateObject private var vm = CreateClubViewModel()
    
    // Kategori Seçimi İçin
    let categories = ["Teknoloji", "Sanat", "Spor", "Sosyal Sorumluluk", "Kariyer", "Eğlence", "Genel"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // LoginView ile aynı soft arkaplan
                LiquidBackground()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        
                        // MARK: - Resim Seçici (Gerçek)
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $vm.selectedItem, matching: .images) {
                                ZStack {
                                    if let image = vm.selectedImage {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 110, height: 110)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(.white, lineWidth: 2))
                                            .shadow(radius: 4)
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(.thinMaterial)
                                                .frame(width: 110, height: 110)
                                                .overlay(
                                                    Circle().stroke(.white.opacity(0.5), lineWidth: 1)
                                                )
                                            
                                            Image(systemName: "camera.fill")
                                                .font(.title)
                                                .foregroundStyle(.secondary)
                                        }
                                        .shadow(radius: 5)
                                    }
                                    
                                    // Düzenle ikonu
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 32, height: 32)
                                        .overlay(Image(systemName: "pencil").font(.caption).bold())
                                        .offset(x: 35, y: 35)
                                        .shadow(radius: 2)
                                }
                            }
                            
                            Text(vm.selectedImage == nil ? "Logo Seç" : "Logoyu Değiştir")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 20)
                        
                        // MARK: - Form Kartı
                        GlassCard {
                            VStack(spacing: 20) {
                                GlassTextField(title: "Kulüp Adı", text: $vm.name, icon: "person.3.fill")
                                
                                // Kategori Picker
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Kategori")
                                        .font(.caption).foregroundStyle(.secondary).padding(.leading, 4)
                                    
                                    Menu {
                                        ForEach(categories, id: \.self) { cat in
                                            Button(cat) { vm.category = cat }
                                        }
                                    } label: {
                                        HStack {
                                            Label(vm.category, systemImage: "tag.fill")
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(14)
                                        .background(.thinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.4), lineWidth: 1))
                                    }
                                }
                                
                                GlassTextField(title: "Vizyon / Misyon", text: $vm.vision, icon: "target", isMultiLine: true)
                                
                                GlassTextField(title: "Hakkında", text: $vm.description, icon: "text.alignleft", isMultiLine: true)
                                
                                GlassTextField(title: "İletişim E-posta", text: $vm.contactEmail, icon: "envelope.fill")
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                            }
                        }
                        
                        // MARK: - Kaydet Butonu (Yeşil Uyumlu)
                        Button {
                            guard let uid = session.currentUser?.uid else { return }
                            Task {
                                await vm.submitClub(creatorId: uid) {
                                    dismiss()
                                }
                            }
                        } label: {
                            HStack {
                                if vm.isLoading { ProgressView().tint(.white) }
                                Text("Kulübü Oluştur")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(GreenCapsuleStyle(disabled: !vm.isValid || vm.isLoading))
                        .disabled(!vm.isValid || vm.isLoading)
                        .padding(.bottom, 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yeni Kulüp")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Hata", isPresented: $vm.showError) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(vm.errorMessage ?? "Bilinmeyen bir hata oluştu.")
        }
    }
}

// MARK: - Custom Green Style for Buttons
struct GreenCapsuleStyle: ButtonStyle {
    var disabled: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .background(
                // LoginView'deki yeşil tonlarına uygun, biraz daha koyu bir gradyan
                LinearGradient(colors: [
                    disabled ? .gray : Color(red: 0.15, green: 0.45, blue: 0.25), // Koyu Orman Yeşili
                    disabled ? .gray.opacity(0.8) : Color(red: 0.25, green: 0.65, blue: 0.55) // Teal/Yeşil
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .shadow(color: disabled ? .clear : Color.green.opacity(0.3), radius: 10, y: 5)
    }
}
