//
//  LoginViewModel.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import SwiftUI
import Combine

/// ViewModel: Ekran durumunu ve aksiyonları yönetir.
/// İstediğin gibi **AuthManager**'dan **kalıtım** alıyor.
@MainActor
final class LoginViewModel: AuthManager {

    // UI State
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isSecure: Bool = true
    @Published var isLoginMode: Bool = true       // true: Giriş, false: Kayıt
    @Published var rememberMe: Bool = true
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""

    // Basit form doğrulama
    var isPrimaryEnabled: Bool {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard password.count >= 6 else { return false }
        return true
    }

    // Ana buton aksiyonu
    func handlePrimaryAction(presenting: AnyObject? = nil) async {
        isLoading = true
        defer { isLoading = false }
        do {
            if isLoginMode {
                _ = try await signIn(email: email, password: password)
                alertMessage = "Giriş başarılı 🎉"
            } else {
                _ = try await register(email: email, password: password)
                alertMessage = "Kayıt oluşturuldu 🎉"
            }
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        showAlert = true
    }

    func handleForgotPassword() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await sendPasswordReset(email: email)
            alertMessage = "Şifre sıfırlama bağlantısı e-postana gönderildi."
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        showAlert = true
    }

    func handleApple() async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await signInWithApple()
            alertMessage = "Apple ile giriş başarılı 🎉"
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        showAlert = true
    }

    func handleGoogle(presenting: AnyObject?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await signInWithGoogle(presenting: presenting)
            alertMessage = "Google ile giriş başarılı 🎉"
        } catch {
            alertMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
        showAlert = true
    }
}
