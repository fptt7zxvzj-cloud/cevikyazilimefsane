//
//  EventListViewModel.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 24.12.2025.
//


import SwiftUI
import Combine

@MainActor
class EventListViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let manager = EventManager()
    
    func loadEvents() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            events = try await manager.fetchAllEvents()
        } catch {
            errorMessage = error.localizedDescription
            print("Etkinlikler çekilemedi: \(error.localizedDescription)")
        }
    }
}
