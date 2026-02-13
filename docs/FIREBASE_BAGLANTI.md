# Kendi Firebase Projenize Bağlanma

Uygulamayı kendi Firebase projenize bağlamak için aşağıdaki adımları izleyin.

## 1. Gereksinimler

- Flutter SDK yüklü
- Google hesabı (Firebase için)
- (İsteğe bağlı) Node.js — Cloud Functions deploy için

## 2. Firebase CLI ve FlutterFire CLI

Terminalde:

```bash
# Firebase CLI (yoksa)
npm install -g firebase-tools

# Firebase’e giriş
firebase login

# FlutterFire CLI
dart pub global activate flutterfire_cli
```

## 3. Projeyi Firebase projenize bağlama

Proje kök dizininde (`vestiyer_app`):

```bash
dart run flutterfire configure
```

Bu komut:

- Mevcut Firebase projelerinizi listeler veya yeni proje oluşturmanızı ister
- Seçtiğiniz projede **Android** ve **iOS** uygulamalarını oluşturur veya mevcut olanları kullanır
- `lib/firebase_options.dart` dosyasını (kendi projenize göre) oluşturur/günceller
- **Android:** `android/app/google-services.json` indirir
- **iOS:** `ios/Runner/GoogleService-Info.plist` indirir

Kendi projenizi seçin; böylece tüm Firebase ayarları (Auth, Firestore, Functions vb.) bu projeye bağlanır.

## 4. Cloud Functions (AI kombin vb.) için

Backend (Functions) aynı Firebase projesinde çalışacaksa:

```bash
# Proje kökünde
cd functions
npm install
```

Firebase Console’da bu proje için **Functions** ve **Firestore** etkin olsun. Deploy için:

```bash
firebase deploy --only functions
```

Önce `firebase use` ile doğru projeyi seçtiğinizden emin olun (örn. `firebase use <project-id>`).

## 5. Kontrol

- `lib/firebase_options.dart` projenize ait `apiKey`, `projectId`, `appId` vb. içermeli
- `android/app/google-services.json` var mı kontrol edin
- Uygulamayı çalıştırın: `flutter run` — giriş, Firestore, kombin önerisi kendi projenize bağlı çalışacaktır

## Not

- `firebase_options.dart` ve `google-services.json` / `GoogleService-Info.plist` genelde **versiyon kontrolüne eklenir**; içlerinde sadece proje tanımlayıcıları vardır, gizli anahtar değil. Yine de paylaşmadan önce ekip politikasına göre `.gitignore` ile hariç tutabilirsiniz.
- Farklı ortamlar (geliştirme / production) için ayrı Firebase projeleri kullanıyorsanız, her ortamda bir kez `dart run flutterfire configure` çalıştırıp ilgili projeyi seçmeniz yeterlidir.
