//
//  AdminUserListView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//


//
//  AdminUserListView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//

import SwiftUI
import Combine

struct AdminUserListView: View {
    @StateObject private var vm = AdminUserListViewModel()
    
    var body: some View {
        ZStack {
            LiquidBackground() // Senin mevcut tasarımın
            
            if vm.isLoading {
                ProgressView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(vm.users) { user in
                            UserRowCard(user: user) {
                                vm.selectedUser = user
                                vm.showRoleSheet = true
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Kullanıcı Yönetimi")
        .onAppear {
            Task { await vm.loadUsers() }
        }
        // AC 1: Rol Düzenleme Modalı
        .sheet(isPresented: $vm.showRoleSheet) {
            if let user = vm.selectedUser {
                RoleEditSheet(user: user, onRoleChanged: { newRole in
                    Task {
                        await vm.updateRole(uid: user.uid, role: newRole)
                    }
                })
                .presentationDetents([.height(350)])
                .presentationCornerRadius(24)
            }
        }
        .alert("Bilgi", isPresented: $vm.showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(vm.alertMessage)
        }
    }
}

// MARK: - ViewModel
@MainActor
class AdminUserListViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var isLoading = false
    @Published var selectedUser: UserProfile?
    @Published var showRoleSheet = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    private let manager = AdminManager()
    
    func loadUsers() async {
        isLoading = true
        do {
            users = try await manager.fetchAllUsers()
        } catch {
            print("Hata: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func updateRole(uid: String, role: String) async {
        // AC 2: Rol atama işlemi
        do {
            try await manager.updateUserRole(uid: uid, newRole: role)
            
            // Listeyi yerelde güncelle (Tekrar fetch atmaya gerek yok)
            if let index = users.firstIndex(where: { $0.uid == uid }) {
                users[index].role = role
            }
            
            alertMessage = "Kullanıcı rolü başarıyla güncellendi: \(role)"
            showAlert = true
            showRoleSheet = false
        } catch {
            alertMessage = "Hata oluştu: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Components

struct UserRowCard: View {
    let user: UserProfile
    let onEdit: () -> Void
    
    var body: some View {
        GlassCard {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(Text(user.displayName.prefix(1)).bold())
                
                VStack(alignment: .leading) {
                    Text(user.displayName)
                        .font(.headline)
                    Text(user.email ?? "No Email")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Mevcut Rol Göstergesi
                Text(roleLabel(for: user.role))
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(roleColor(for: user.role).opacity(0.2))
                    .foregroundStyle(roleColor(for: user.role))
                    .clipShape(Capsule())
                
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
        }
    }
    
    func roleLabel(for role: String) -> String {
        switch role {
        case "admin": return "Sistem Yöneticisi"
        case "club_manager": return "Kulüp Yöneticisi"
        default: return "Standart Üye"
        }
    }
    
    func roleColor(for role: String) -> Color {
        switch role {
        case "admin": return .red
        case "club_manager": return .orange
        default: return .gray
        }
    }
}

// AC 1 & 2: Rol Seçim Ekranı
struct RoleEditSheet: View {
    let user: UserProfile
    let onRoleChanged: (String) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var selectedRole: String
    
    init(user: UserProfile, onRoleChanged: @escaping (String) -> Void) {
        self.user = user
        self.onRoleChanged = onRoleChanged
        _selectedRole = State(initialValue: user.role)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("\(user.displayName) İçin Rol Ata")
                .font(.headline)
                .padding(.top)
            
            Picker("Rol", selection: $selectedRole) {
                Text("Standart Üye").tag("user")
                Text("Kulüp Yöneticisi").tag("club_manager") // Yeni Rol
                Text("Sistem Yöneticisi").tag("admin")
            }
            .pickerStyle(.wheel)
            
            Button {
                onRoleChanged(selectedRole)
            } label: {
                Text("Değişiklikleri Kaydet")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
        }
        .background(LiquidBackground().opacity(0.5))
    }
}
