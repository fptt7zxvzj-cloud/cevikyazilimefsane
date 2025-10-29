//
//  AppSession.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import Foundation
import Combine

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

/// Uygulama genel oturum yöneticisi.
/// AuthManager'dan kalıtım alır; Firebase Auth durumunu izler ve
/// Firestore'dan profil var/yok bilgisini getirir.
@MainActor
final class AppSession: AuthManager {
    @Published var currentUser: AppUser?
    @Published var isSignedIn: Bool = false
    @Published var profileExists: Bool? // nil: yükleniyor, true/false: sonuç

    private let firestore = FirestoreManager()

    override init() {
        super.init()

        #if canImport(FirebaseAuth)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let u = user {
                self.currentUser = AppUser(uid: u.uid, email: u.email)
                self.isSignedIn = true
                Task { await self.refreshProfileStatus() }
            } else {
                self.currentUser = nil
                self.isSignedIn = false
                self.profileExists = nil
            }
        }
        #else
        // FirebaseAuth yoksa, LoginView sahte akışla çalışır ama gerçek oturum olmaz.
        self.currentUser = nil
        self.isSignedIn = false
        self.profileExists = nil
        #endif
    }

    func refreshProfileStatus() async {
        guard let uid = currentUser?.uid else { profileExists = nil; return }
        do {
            profileExists = try await firestore.profileExists(uid: uid)
        } catch {
            // Firestore yoksa veya hata olursa profil durumunu bilinmiyor yapalım.
            profileExists = nil
        }
    }
}
