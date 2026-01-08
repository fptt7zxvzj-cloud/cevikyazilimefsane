//
//  ClubModels.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 26.11.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage // Storage eklendi
import UIKit

// MARK: - Club Model
public struct Club: Identifiable, Codable {
    @DocumentID public var id: String?
    public var name: String
    public var description: String
    public var vision: String
    public var rules: String
    public var category: String
    public var imageUrl: String?
    public var contactEmail: String?
    public var createdBy: String // Admin UID
    public var createdAt: Date
    public var memberCount: Int
    public var members: [String] = []
    
    public var safeId: String { id ?? UUID().uuidString }
}

// MARK: - Club Manager
class ClubManager: FirestoreManager {
    static let shared = ClubManager()
    // 1. Resmi Storage'a yükle ve URL döndür
    @MainActor
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {
            throw AuthManagerError.custom("Resim verisi oluşturulamadı.")
        }
        
        let storageRef = Storage.storage().reference()
        let path = "club_logos/\(UUID().uuidString).jpg"
        let fileRef = storageRef.child(path)
        
        // Yükleme metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // Put data
        _ = try await fileRef.putDataAsync(imageData, metadata: metadata)
        
        // URL al
        let url = try await fileRef.downloadURL()
        return url.absoluteString
    }
    
    // 2. Kulübü Firestore'a kaydet
    @MainActor
    func createClub(_ club: Club) async throws {
        let db = Firestore.firestore()
        let ref = db.collection("clubs").document()
        try ref.setData(from: club)
    }
    
    func fetchClub(id: String) async throws -> Club? {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("clubs").document(id).getDocument()
        return try? snapshot.data(as: Club.self)
    }
    
    // 3. Kulüpleri getir
    @MainActor
    func fetchClubs() async throws -> [Club] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("clubs")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Club.self) }
    }
}

extension ClubManager {
    
    // 1. KULÜBE KATIL (ID'yi listeye ekle)
    @MainActor
    func joinClub(clubId: String, userId: String) async throws {
        let db = Firestore.firestore()
        let ref = db.collection("clubs").document(clubId)
        
        // Atomik güncelleme: Hem listeye ekle hem sayıyı artır
        try await ref.updateData([
            "members": FieldValue.arrayUnion([userId]),
            "memberCount": FieldValue.increment(Int64(1))
        ])
    }
    
    // 2. KULÜPTEN AYRIL (Opsiyonel: ID'yi listeden sil)
    @MainActor
    func leaveClub(clubId: String, userId: String) async throws {
        let db = Firestore.firestore()
        let ref = db.collection("clubs").document(clubId)
        
        try await ref.updateData([
            "members": FieldValue.arrayRemove([userId]),
            "memberCount": FieldValue.increment(Int64(-1))
        ])
    }
    
    // 3. ÜYE PROFİLLERİNİ GETİR (ID listesinden UserProfile objelerine)
    @MainActor
    func fetchMembersProfiles(memberIds: [String]) async throws -> [UserProfile] {
        guard !memberIds.isEmpty else { return [] }
        
        let db = Firestore.firestore()
        
        // NOT: Firestore "in" sorgusu en fazla 10 eleman kabul eder.
        // Eğer üye sayısı çoksa bunu parçalı yapmak gerekir.
        // Şimdilik basitlik adına chunk mantığı olmadan;
        // 10'dan az üye varsa "whereField", çoksa tek tek çekip birleştireceğiz.
        
        // Yöntem: TaskGroup ile paralel çekim (En garantisi)
        var profiles: [UserProfile] = []
        
        return try await withThrowingTaskGroup(of: UserProfile?.self) { group in
            for uid in memberIds {
                group.addTask {
                    let doc = try? await db.collection("users").document(uid).getDocument()
                    if let data = doc?.data(), let id = doc?.documentID {
                        // FirestoreManager içindeki decode metodunu public yapman gerekebilir
                        // Ya da manuel decode:
                        let name = data["displayName"] as? String ?? "İsimsiz"
                        let email = data["email"] as? String
                        return UserProfile(uid: id, email: email, displayName: name, role: "user")
                    }
                    return nil
                }
            }
            
            for try await profile in group {
                if let profile = profile {
                    profiles.append(profile)
                }
            }
            return profiles
        }
    }
    
    
}
