import SwiftUI
import FirebaseCore
import Combine

@main
struct YeniKulupYonetimApp: App {
    @StateObject private var session = AppSession()

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isSignedIn {
                    // Profil durumunu hâlâ yüklerken
                    if session.profileExists == nil {
                        ProgressView("Profil bilgileriniz yükleniyor...")
                    } else if session.profileExists == false {
                        ProfileCreationView()
                    } else {
                        MainMenuView()
                    }
                } else {
                    LoginView() // mevcut LoginView'ını kullan
                }
            }
            .environmentObject(session)
        }
    }
}
