//
//  MainMenuView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import SwiftUI
import Combine

struct MainMenuView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        NavigationStack {
            List {
                Section("Hesap") {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(session.currentUser?.email ?? "Bilinmiyor")
                                .font(.headline)
                            if let uid = session.currentUser?.uid {
                                Text(uid).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Örnek Menü") {
                    NavigationLink("Kulüp Listem") { Text("Stub View") }
                    NavigationLink("Ayarlar") { Text("Stub Settings") }
                }

                Section {
                    Button(role: .destructive) {
                        try? session.signOut()
                    } label: {
                        Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Ana Menü")
        }
    }
}
