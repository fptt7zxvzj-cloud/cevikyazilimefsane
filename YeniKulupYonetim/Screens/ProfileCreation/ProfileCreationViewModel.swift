//
//  ProfileCreationViewModel.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import SwiftUI
import Combine

@MainActor
final class ProfileCreationViewModel: ProfileCreationManager {
    @Published var displayName: String = ""
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    var isValid: Bool { displayName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 }

    func submit(using session: AppSession) async {
        guard let user = session.currentUser else {
            alertMessage = "Kullanıcı oturumu bulunamadı."; showAlert = true; return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await createProfile(uid: user.uid, email: user.email, displayName: displayName)
            await session.refreshProfileStatus() // root akış MainMenuView'a geçer
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            showAlert = true
        }
    }
}
