//
//  ProfileCreationView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import SwiftUI
import Combine

struct ProfileCreationView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var vm = ProfileCreationViewModel()

    var body: some View {
        ZStack {
            LinearGradient(colors: [
                Color(.displayP3, red: 0.96, green: 0.99, blue: 0.92, opacity: 1),
                Color(.displayP3, red: 0.90, green: 0.93, blue: 1.0, opacity: 1)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Logo (varsa)
                Image("appLogo")
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFit()
                    .frame(height: 72)
                    .padding(.top, 24)

                Text("Profil Oluştur")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.text.rectangle")
                            .font(.title3).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Görünen İsim").font(.footnote).foregroundStyle(.secondary)
                            TextField("Adın", text: $vm.displayName)
                                .textInputAutocapitalization(.words)
                        }
                    }
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                    )

                    Button {
                        Task { await vm.submit(using: session) }
                    } label: {
                        HStack {
                            if vm.isLoading { ProgressView().tint(.white) }
                            Text("Kaydı Tamamla").fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                    }
                    .buttonStyle(PrimaryCapsuleStyle(disabled: !vm.isValid || vm.isLoading))
                    .disabled(!vm.isValid || vm.isLoading)
                }
                .padding(20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)

                Spacer()

                Button {
                    try? session.signOut()
                } label: {
                    Text("Çıkış yap").foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .alert("Bilgi", isPresented: $vm.showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: { Text(vm.alertMessage) }
    }
}
