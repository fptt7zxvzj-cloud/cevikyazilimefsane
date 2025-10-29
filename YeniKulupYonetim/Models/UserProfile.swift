//
//  UserProfile.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import Foundation
import Combine

public struct UserProfile: Codable, Identifiable, Equatable {
    public var id: String { uid }
    public let uid: String
    public var email: String?
    public var displayName: String
    public var createdAt: Date
    public var updatedAt: Date?

    public init(uid: String, email: String?, displayName: String, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
