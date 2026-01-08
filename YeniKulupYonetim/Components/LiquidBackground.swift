//
//  GlassDesignSystem.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 26.11.2025.
//

import SwiftUI

/// Arka plan için LoginView ile aynı soft gradyan
struct LiquidBackground: View {
    var body: some View {
        LinearGradient(colors: [
            Color(.displayP3, red: 0.92, green: 0.98, blue: 0.86, opacity: 1),
            Color(.displayP3, red: 0.90, green: 0.93, blue: 1.0, opacity: 1)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
        .ignoresSafeArea()
    }
}
/// Glassmorphism Kart Stili
struct GlassCard<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial) // iOS Buzlu Cam Efekti
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// Form elemanları için Glass TextField
struct GlassTextField: View {
    var title: String
    @Binding var text: String
    var icon: String? = nil
    var isMultiLine: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fontWeight(.medium)
                .padding(.leading, 4)
            
            HStack(alignment: isMultiLine ? .top : .center, spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundStyle(.secondary)
                        .padding(.top, isMultiLine ? 6 : 0)
                }
                
                if isMultiLine {
                    TextEditor(text: $text)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden) // TextEditor gri arka planını kaldırır
                } else {
                    TextField("", text: $text)
                }
            }
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1)
            )
        }
    }
}
