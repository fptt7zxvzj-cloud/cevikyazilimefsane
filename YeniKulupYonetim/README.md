Kulüplük
- Kullanıcı kimlik doğrulaması ve basit profil yönetimi içeren, SwiftUI + MVVM yaklaşımıyla hazırlanmış bir iOS uygulaması iskeleti.

Kısa Özet
- Bu proje, FirebaseAuth ile giriş/çıkış ve sosyal oturum açmayı kolaylaştıran, Firestore ile kullanıcı profilini belge-bazlı tutan, MVVM ile UI ve iş mantığını ayıran bir yapı sunar. Uygulama, açılışta oturum ve profil durumuna göre kullanıcıyı doğru ekrana yönlendirir (Login → Profil Oluşturma → Ana Menü). Hedef; hızlı başlangıç, temiz mimari ve genişlemeye açık bir iskelet sağlamaktır.

Backend — Temel Özellikler ve Nedenleri
- FirebaseAuth
- Ne yapar? E-posta/şifre ile giriş; Google ve Apple ile oturuma hazır altyapı.
- Neden? Tek çatı altında çoklu yöntem, oturum durumu dinleme ile UI’nin otomatik güncellenmesi, kolay kurulum ve geniş topluluk.
- FirebaseFirestore
- Ne yapar? users/{uid} altında profil saklama (document-based).
- Neden? Esnek/şemasız yapı ile hızlı CRUD, istemciden doğrudan erişim, güvenlik kurallarıyla kullanıcıyı kendi verisiyle sınırlandırma.
- Asenkron Akış (Combine + Swift Concurrency)
- Ne yapar? Ağ/kimlik işlemlerinde akıcı deneyim ve sade async/await kodu.
- Neden? Modern iOS yaklaşımı; okunabilirlik ve bakım kolaylığı.
- Servis Katmanı
- Ne yapar? Auth ve Firestore işlemlerini tek merkezde toplar (View/VM Firebase detayından bağımsız).
- Neden? Ayrık sorumluluk, yeniden kullanım, bakım kolaylığı.

Frontend — Temel Özellikler ve Nedenleri
- Ekran Akışı
- Login → Profil Oluşturma → Ana Menü (oturum ve profil varlığına göre otomatik yönlendirme).
- Neden? Net kullanıcı yolculuğu; ilk deneyimde minimum sürtünme.
- Login Ekranı
- E-posta/şifre, “Şifremi unuttum”, Giriş/Kayıt toggle, Google/Apple butonları (hazır altyapı).
- Neden? Alışılmış düzen; sosyal girişler tamamlandığında ek bir mimari değişiklik gerektirmez.
- Profil Oluşturma
- Görünen ad alınıp profil kaydedilir; ardından ana akışa geçilir.
- Neden? Hızlı başlangıç; kullanıcıyı yormayan tek adım.
- Ana Menü
- E-posta/UID görüntüleme, örnek menüler, Çıkış.
- Neden? Basit iskelet; proje büyüdükçe modüler genişleme.

Mimari (MVVM) — Yüksek Seviye
- Model: AppUser, UserProfile
- Service/Repository: AuthManager, FirestoreManager, ProfileCreationManager
- State/Session: AppSession (auth state dinler, profil varlığını kontrol eder)
- ViewModel: LoginViewModel (giriş/kayıt/şifre sıfırlama/sosyal giriş tetikleyicileri), ProfileCreationViewModel (profil oluşturma)
- View: LoginView, ProfileCreationView, MainMenuView (salt UI)
- Akış: View (buton) → ViewModel (servis çağrısı) → Service (Firebase) → sonuç → ViewModel @Published günceller → View yeniden çizilir

Neden Bu Seçimler?
- FirebaseAuth: Çoklu oturum yöntemi tek pakette; durum dinleme ile sade UI entegrasyonu.
- Firestore: Basit profil verisi için hızlı ve esnek; güvenlik kurallarıyla daraltılabilir.
- MVVM: Test edilebilirlik ve bakım kolaylığı; UI ve veri erişimi ayrışır.

Yol Haritası (Kısa)
- Sosyal girişleri (Google/Apple) prod akışlarıyla tamamlama
- Firestore güvenlik kurallarını sıkılaştırma (kullanıcı sadece kendi dokümanına erişsin)
- Form doğrulamaları ve yükleme durumlarını iyileştirme
- Profil verisini (ör. avatar) kademeli zenginleştirme
- Hata mesajlarını sade ve yönlendirici hâle getirme

Klasör Yapısı (özet)
YeniKulupYonetim/
└─ YeniKulupYonetim/
   ├─ App/
   │  └─ YeniKulupYonetimApp.swift
   ├─ Core/
   │  ├─ AppSession.swift
   │  ├─ AuthManager.swift
   │  ├─ FirestoreManager.swift
   │  └─ ProfileCreationManager.swift
   ├─ Models/
   │  └─ UserProfile.swift
   ├─ Screens/
   │  ├─ Login/
   │  │  ├─ LoginView.swift
   │  │  └─ LoginViewModel.swift
   │  ├─ MainMenu/
   │  │  └─ MainMenuView.swift
   │  └─ ProfileCreation/
   │     ├─ ProfileCreationView.swift
   │     └─ ProfileCreationViewModel.swift
   ├─ Assets/
   └─ GoogleService-Info.plist
Pods/
Products/
Frameworks/
