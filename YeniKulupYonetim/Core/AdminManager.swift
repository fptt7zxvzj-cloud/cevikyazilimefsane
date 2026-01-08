//
//  AdminManager.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//


//
//  AdminManager.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//

import Foundation
import FirebaseFirestore

class AdminManager: FirestoreManager {
    
    // Tüm kullanıcıları getir (Admin paneli listesi için)
    @MainActor
    func fetchAllUsers() async throws -> [UserProfile] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("users")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        var users: [UserProfile] = []
        for doc in snapshot.documents {
            let data = doc.data()
            // Mevcut decode fonksiyonunu kullanabilmek için manuel mapping veya
            // FirestoreManager içindeki decodeProfile metodunu static public yapman gerekebilir.
            // Şimdilik burada manuel decode ediyoruz:
            if let uid = data["uid"] as? String,
               let displayName = data["displayName"] as? String {
                
                let email = data["email"] as? String
                let role = data["role"] as? String ?? "user"
                let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                
                let profile = UserProfile(uid: uid, email: email, displayName: displayName, role: role, createdAt: createdAt)
                users.append(profile)
            }
        }
        return users
    }
    
    // Kullanıcının rolünü güncelle (AC 2 - Veritabanı Güncellemesi)
    @MainActor
    func updateUserRole(uid: String, newRole: String) async throws {
        let db = Firestore.firestore()
        try await db.collection("users").document(uid).updateData([
            "role": newRole,
            "updatedAt": Date()
        ])
    }
}