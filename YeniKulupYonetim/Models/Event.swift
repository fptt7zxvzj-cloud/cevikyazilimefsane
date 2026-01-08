//
//  Event.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//


import Foundation
import FirebaseFirestore

// MARK: - Event Model
public struct Event: Identifiable, Codable {
    @DocumentID public var id: String?
    public var clubId: String
    public var title: String
    public var description: String
    public var date: Date
    public var location: String
    public var imageUrl: String?
    public var clubName: String? // Etkinliğin hangi kulübe ait olduğu (opsiyonel)
    
    // UI için yardımcı formatlayıcılar
    public var dayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    public var monthString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMM"
        return formatter.string(from: date).uppercased()
    }
    
    public var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Event Manager
class EventManager: FirestoreManager {
    @MainActor
    func fetchEvents(for clubId: String) async throws -> [Event] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("events")
            .whereField("clubId", isEqualTo: clubId) // Sadece bu kulübünkiler
            .order(by: "date", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Event.self) }
    }

    // YENİ: Etkinlik Oluştur
    @MainActor
    func createEvent(_ event: Event) async throws {
        let db = Firestore.firestore()
        try db.collection("events").addDocument(from: event)
    }
    
    @MainActor
    func fetchAllEvents() async throws -> [Event] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("events")
            .order(by: "date", descending: false) // Tarihe göre sırala
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Event.self) }
    }
}
