//
//  ProfileCreationManager.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//

import Foundation
import Combine

open class ProfileCreationManager: FirestoreManager {
    @MainActor
    open func createProfile(uid: String, email: String?, displayName: String) async throws -> UserProfile {
        

        var profile = UserProfile(
            uid: uid,
            email: email,
            displayName: displayName,
            role: "user",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await upsertProfile(profile)
        return profile
    }
}
