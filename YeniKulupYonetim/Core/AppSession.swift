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
    
    @Published var profileExists: Bool?
    
    // YENİ: Tam profil verisini burada tutacağız
    @Published var userProfile: UserProfile?

    private let firestore = FirestoreManager()

    override init() {
        super.init()

        #if canImport(FirebaseAuth)
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            if let u = user {
                self.currentUser = AppUser(uid: u.uid, email: u.email)
                self.isSignedIn = true
                Task {
                    await self.refreshProfileStatus()
                    // YENİ: Giriş yapınca profili de çek
                    await self.fetchFullProfile(uid: u.uid)
                }
            } else {
                self.currentUser = nil
                self.userProfile = nil // Çıkışta sıfırla
                self.isSignedIn = false
                self.profileExists = nil
            }
        }
        #endif
    }

    func refreshProfileStatus() async {
        guard let uid = currentUser?.uid else { profileExists = nil; return }
        do {
            profileExists = try await firestore.profileExists(uid: uid)
        } catch {
            profileExists = nil
        }
    }
    
    // YENİ FONKSİYON: Profili getir ve memory'ye yaz
    func fetchFullProfile(uid: String) async {
        do {
            let profile = try await firestore.fetchProfile(uid: uid)
            self.userProfile = profile
        } catch {
            print("Profil çekilemedi: \(error.localizedDescription)")
        }
    }
}
