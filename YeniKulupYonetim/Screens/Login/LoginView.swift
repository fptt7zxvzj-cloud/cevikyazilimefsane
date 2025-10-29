//
//  LoginView.swift
//  YeniKulupYonetim
//
//  Created by Ömer on 29.10.2025.
//

import SwiftUI
import Combine

/// Sadece UI. İş mantığı yok; ViewModel aksiyonlarına bağlanıyor.
public struct LoginView: View {
    @StateObject private var vm = LoginViewModel()

    public init() {}

    public var body: some View {
        ZStack {
            // MARK: Background
            LinearGradient(colors: [
                Color(.displayP3, red: 0.92, green: 0.98, blue: 0.86, opacity: 1),
                Color(.displayP3, red: 0.90, green: 0.93, blue: 1.0, opacity: 1)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            // Dekoratif açılı şerit (ekrandaki örneğe göz kırpan modern header)
            VStack(spacing: 0) {
                AngularHeader()
                    .frame(height: 120)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
            }
            .ignoresSafeArea(edges: .top)

            // MARK: Content
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header           // <- Yalnızca logo
                    modePicker

                    // Card
                    VStack(spacing: 16) {
                        ModernTextField(title: "E-posta", text: $vm.email, symbol: "envelope")
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                        ModernSecureField(title: "Şifre", text: $vm.password, isSecure: $vm.isSecure)

                        HStack {

                            Spacer()
                            Button("Şifremi unuttum") {
                                Task { await vm.handleForgotPassword() }
                            }
                            .font(.caption).bold()
                        }
                        .padding(.top, 4)

                        Button {
                            Task { await vm.handlePrimaryAction(presenting: topController()) }
                        } label: {
                            HStack {
                                if vm.isLoading { ProgressView().tint(.white) }
                                Text(vm.isLoginMode ? "Giriş yap" : "Kayıt ol")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PrimaryCapsuleStyle(disabled: !vm.isPrimaryEnabled))
                        .disabled(!vm.isPrimaryEnabled || vm.isLoading)
                        .padding(.top,4)

                        HStack {
                            Rectangle().frame(height: 1).foregroundStyle(.thinMaterial)
                            Text("veya").font(.footnote).foregroundStyle(.secondary)
                            Rectangle().frame(height: 1).foregroundStyle(.thinMaterial)
                        }
                        .padding(.vertical, 6)

                        HStack(spacing: 12) {
                            SocialButton(title: "Apple ile devam et", systemImage: "apple.logo") {
                                Task { await vm.handleApple() }
                            }
                            SocialButton(title: "Google ile devam et",
                                         customImageName: "googleicon") {
                                Task { await vm.handleGoogle(presenting: topController()) }
                            }

                        }

                        terms
                    }
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(LinearGradient(
                                colors: [Color.white.opacity(0.8), Color.white.opacity(0.1)],
                                startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 10)
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 24)
            }
            
        }
        .alert("Bilgi", isPresented: $vm.showAlert, actions: {
            Button("Tamam", role: .cancel) { }
        }, message: {
            Text(vm.alertMessage)
        })
    }

    // MARK: - Subviews

    /// Üstte sadece logo
    private var header: some View {
        HStack {
            Spacer()
            Image("appLogo")
                .resizable()
                .scaledToFit()
                .frame(height: 96)
                .accessibilityLabel("Uygulama Logosu")

            Spacer()
        }
    }

    private var modePicker: some View {
        Picker("", selection: $vm.isLoginMode) {
            Text("Giriş").tag(true)
            Text("Kayıt").tag(false)
        }
        .pickerStyle(.segmented)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var terms: some View {
        Text("Devam ederek **Kullanım Şartları** ve **Gizlilik Politikası**'nı kabul etmiş olursun.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 6)
    }

    // MARK: Helpers
    private func topController() -> AnyObject? {
        // Google akışı gibi SDK'lar için gerekirse ViewController sağlamak adına.
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}

// MARK: - Components

private struct AngularHeader: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            
        }
    }
}

private struct ModernTextField: View {
    let title: String
    @Binding var text: String
    var symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.title3).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.footnote).foregroundStyle(.secondary)
                TextField("", text: $text)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}

private struct ModernSecureField: View {
    let title: String
    @Binding var text: String
    @Binding var isSecure: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill").font(.title3).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.footnote).foregroundStyle(.secondary)
                Group {
                    if isSecure {
                        SecureField("", text: $text)
                    } else {
                        TextField("", text: $text)
                    }
                }
            }
            Spacer(minLength: 8)
            Button {
                withAnimation(.snappy) { isSecure.toggle() }
            } label: {
                Image(systemName: isSecure ? "eye.slash" : "eye")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
        )
    }
}

struct PrimaryCapsuleStyle: ButtonStyle {
    var disabled: Bool = false
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [
                    disabled ? .gray : .black,
                    disabled ? .gray.opacity(0.8) : .blue
                ], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

private struct SocialButton: View {
    let title: String
    var systemImage: String? = nil
    var customImageName: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage).font(.title3.bold())
                } else if let customImageName {
                    Image(customImageName)              // <- asset'ten oku
                        .resizable()
                        .renderingMode(.original)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                       
                }
                Text(title).fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}


// MARK: - Preview
#Preview {
    LoginView()
}
