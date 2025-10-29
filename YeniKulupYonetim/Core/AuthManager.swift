//
//  AppUser.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//


import Foundation
import Combine

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import AuthenticationServices

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// Uygulama içinde auth bağımsız bir kullanıcı modeli kullanalım.
// Firebase obje tiplerine bağımlılığı ViewModel ve View'den uzak tutar.
public struct AppUser: Sendable, Equatable {
    public let uid: String
    public let email: String?
    public init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
}

public enum AuthManagerError: LocalizedError {
    case notImplemented(String)
    case unknown
    case invalidCredentials
    case cancelled
    case custom(String)

    public var errorDescription: String? {
        switch self {
        case .notImplemented(let msg): return msg
        case .invalidCredentials: return "Kullanıcı adı veya şifre hatalı."
        case .cancelled: return "İşlem iptal edildi."
        case .custom(let msg): return msg
        case .unknown: return "Bilinmeyen bir hata oluştu."
        }
    }
}

/// Servis katmanı: Tüm kimlik doğrulama işlemleri buradan geçer.
/// ViewModel'ler bu sınıftan **kalıtım** alır (isteğin doğrultusunda),
/// böylece ortak auth fonksiyonlarını direkt kullanabilir.
open class AuthManager: ObservableObject {

    @Published public var isLoading: Bool = false
    @Published public var lastError: String?

    public init() {}

    // MARK: - Email / Password

    /// Giriş
    @MainActor
    open func signIn(email: String, password: String) async throws -> AppUser {
        #if canImport(FirebaseAuth)
        let user = try await Self.firebaseSignIn(email: email, password: password)
        return user
        #else
        throw AuthManagerError.notImplemented("FirebaseAuth projeye eklenmedi. Pod/SPM kurulumundan sonra otomatik çalışır.")
        #endif
    }

    /// Kayıt
    @MainActor
    open func register(email: String, password: String) async throws -> AppUser {
        #if canImport(FirebaseAuth)
        let user = try await Self.firebaseRegister(email: email, password: password)
        return user
        #else
        throw AuthManagerError.notImplemented("FirebaseAuth yok. Ekleyince gerçek kayıt aktif olur.")
        #endif
    }

    /// Şifre sıfırlama
    @MainActor
    open func sendPasswordReset(email: String) async throws {
        #if canImport(FirebaseAuth)
        try await Self.firebaseResetPassword(email: email)
        #else
        throw AuthManagerError.notImplemented("FirebaseAuth yok. Ekleyince gerçek sıfırlama aktif olur.")
        #endif
    }

    /// Çıkış
    @MainActor
    open func signOut() throws {
        #if canImport(FirebaseAuth)
        try Auth.auth().signOut()
        #else
        throw AuthManagerError.notImplemented("FirebaseAuth yok. Ekleyince gerçek çıkış aktif olur.")
        #endif
    }

    // MARK: - Apple / Google

    /// Apple ile giriş (nonce vb. akışlar ürün ortamında eklenmeli)
    @MainActor
    open func signInWithApple() async throws -> AppUser {
        #if canImport(FirebaseAuth)
        // Buraya prod için: CryptoKit ile nonce üretimi + ASAuthorizationController ile akış + Firebase credential.
        throw AuthManagerError.notImplemented("Sign in with Apple entegrasyonu için nonce ve ASAuthorizationController akışını ekleyin.")
        #else
        throw AuthManagerError.notImplemented("FirebaseAuth yok. Ekleyince gerçek Apple girişi aktif olur.")
        #endif
    }

    /// Google ile giriş — View tarafı presenting VC gönderir.
    @MainActor
    open func signInWithGoogle(presenting: AnyObject?) async throws -> AppUser {
        #if canImport(FirebaseAuth) && canImport(GoogleSignIn)
        // Ürün ortamında: GIDSignIn.sharedInstance.signIn(withPresenting:) -> idToken + accessToken -> Firebase credential
        throw AuthManagerError.notImplemented("Google Sign-In için GIDSignIn akışını ve Firebase credential'ını ekleyin.")
        #else
        throw AuthManagerError.notImplemented("GoogleSignIn/FirebaseAuth paketleri yok.")
        #endif
    }
}

// MARK: - Firebase köprüleri
#if canImport(FirebaseAuth)
extension AuthManager {
    fileprivate static func firebaseSignIn(email: String, password: String) async throws -> AppUser {
        try await withCheckedThrowingContinuation { cont in
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                if let error { cont.resume(throwing: error); return }
                guard let user = result?.user else { cont.resume(throwing: AuthManagerError.unknown); return }
                cont.resume(returning: AppUser(uid: user.uid, email: user.email))
            }
        }
    }

    fileprivate static func firebaseRegister(email: String, password: String) async throws -> AppUser {
        try await withCheckedThrowingContinuation { cont in
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error { cont.resume(throwing: error); return }
                guard let user = result?.user else { cont.resume(throwing: AuthManagerError.unknown); return }
                cont.resume(returning: AppUser(uid: user.uid, email: user.email))
            }
        }
    }

    fileprivate static func firebaseResetPassword(email: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error { cont.resume(throwing: error) }
                else { cont.resume(returning: ()) }
            }
        }
    }

}
#endif
