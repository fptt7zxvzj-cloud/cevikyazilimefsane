//
//  CreateClubViewModel.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 26.11.2025.
//

import SwiftUI
import Combine
import PhotosUI // Resim seçimi için gerekli

@MainActor
class CreateClubViewModel: ObservableObject {
    // Form Alanları
    @Published var name = ""
    @Published var description = ""
    @Published var vision = ""
    @Published var category = "Genel"
    @Published var contactEmail = ""
    
    // Resim Seçimi
    @Published var selectedItem: PhotosPickerItem? = nil {
        didSet { Task { await loadSelection() } }
    }
    @Published var selectedImage: UIImage? = nil
    
    // Durumlar
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    private let manager = ClubManager()
    
    // Form Validasyonu
    var isValid: Bool {
        !name.isEmpty && !description.isEmpty && !vision.isEmpty
    }
    
    // Seçilen resmi UIImage'e çevir
    private func loadSelection() async {
        guard let item = selectedItem else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let uiImage = UIImage(data: data) {
            self.selectedImage = uiImage
        }
    }
    
    func submitClub(creatorId: String, onSuccess: @escaping () -> Void) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            var finalImageUrl: String? = nil
            
            // 1. Resim varsa yükle
            if let img = selectedImage {
                finalImageUrl = try await manager.uploadImage(img)
            }
            
            // 2. Kulüp objesini oluştur
            let newClub = Club(
                name: name,
                description: description,
                vision: vision,
                rules: "Standart üniversite kulüp kuralları geçerlidir.",
                category: category,
                imageUrl: finalImageUrl,
                contactEmail: contactEmail.isEmpty ? nil : contactEmail,
                createdBy: creatorId,
                createdAt: Date(),
                memberCount: 1
            )
            
            // 3. Kaydet
            try await manager.createClub(newClub)
            onSuccess()
            
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
