//
//  FirestoreManager.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import Foundation
import Combine

#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

open class FirestoreManager: ObservableObject {
    public init() {}

    // Kullanıcı profili var mı?
    @MainActor
    open func profileExists(uid: String) async throws -> Bool {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid)
        return try await withCheckedThrowingContinuation { cont in
            ref.getDocument { snap, err in
                if let err { cont.resume(throwing: err) }
                else { cont.resume(returning: (snap?.exists ?? false)) }
            }
        }
        #else
        throw AuthManagerError.notImplemented("FirebaseFirestore projeye ekli değil.")
        #endif
    }

    // Profili getir
    @MainActor
    open func fetchProfile(uid: String) async throws -> UserProfile {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let ref = db.collection("users").document(uid)
        return try await withCheckedThrowingContinuation { cont in
            ref.getDocument { snap, err in
                if let err { cont.resume(throwing: err); return }
                guard let data = snap?.data(), let uid = snap?.documentID else {
                    cont.resume(throwing: AuthManagerError.unknown); return
                }
                let profile = Self.decodeProfile(uid: uid, data: data)
                cont.resume(returning: profile)
            }
        }
        #else
        throw AuthManagerError.notImplemented("FirebaseFirestore projeye ekli değil.")
        #endif
    }

    // Profil oluştur/güncelle
    @MainActor
    open func upsertProfile(_ profile: UserProfile) async throws {
        #if canImport(FirebaseFirestore)
        let db = Firestore.firestore()
        let ref = db.collection("users").document(profile.uid)
        var payload = Self.encodeProfile(profile)
        payload["updatedAt"] = Date()
        return try await withCheckedThrowingContinuation { cont in
            ref.setData(payload, merge: true) { err in
                if let err { cont.resume(throwing: err) } else { cont.resume(returning: ()) }
            }
        }
        #else
        throw AuthManagerError.notImplemented("FirebaseFirestore projeye ekli değil.")
        #endif
    }

    // MARK: - Mapping helpers (Any <-> UserProfile)

    fileprivate static func encodeProfile(_ p: UserProfile) -> [String: Any] {
        var dict: [String: Any] = [
            "uid": p.uid,
            "email": p.email as Any,
            "displayName": p.displayName,
            "createdAt": p.createdAt
        ]
        if let updated = p.updatedAt { dict["updatedAt"] = updated }
        return dict
    }

    fileprivate static func decodeProfile(uid: String, data: [String: Any]) -> UserProfile {
        let email = data["email"] as? String
        let displayName = (data["displayName"] as? String) ?? ""
        let createdAt = (data["createdAt"] as? Date) ?? Date()
        let updatedAt = data["updatedAt"] as? Date
        return UserProfile(uid: uid, email: email, displayName: displayName, createdAt: createdAt, updatedAt: updatedAt)
    }
}
