# Firebase ve Proje – Yapılacaklar Listesi

## 1. Firebase Console (Tarayıcı)

| # | Yapılacak | Nerede | Durum |
|---|-----------|--------|--------|
| 1 | **Authentication** – Email/Password etkinleştir | Build → Authentication → Sign-in method → Email/Password → Enable | ☐ |
| 2 | **Firestore Database** oluştur | Build → Firestore Database → Create database (Production mode, bölge örn. europe-west1) | ☐ |
| 3 | **Storage** başlat | Build → Storage → Get started (varsayılan bucket) | ☐ |
| 4 | **Blaze (ödeme) plana** geç | Functions kullanmak için zorunlu | ☐ |
| 5 | (İsteğe bağlı) Test kullanıcısı ekle | Authentication → Users → Add user (örn. test@dolap.ai) | ☐ |

---

## 2. OpenAI API Key (Cloud Functions için)

| # | Yapılacak | Nasıl |
|---|-----------|--------|
| 1 | **Secret Manager’da secret oluştur** | Google Cloud Console → Security → Secret Manager → Create secret → İsim: `OPENAI_API_KEY`, değer: `sk-...` |
| 2 | (Alternatif) Firebase config ile: `firebase functions:config:set openai.key="sk-..."` | Kod şu an `process.env.OPENAI_API_KEY` kullanıyor; Secret Manager önerilir. |

---

## 3. Firebase CLI ve Deploy

| # | Yapılacak | Komut / Not |
|---|-----------|-------------|
| 1 | Projeyi seç | `firebase use vestiyer-da67f` (veya kendi project ID’n) |
| 2 | Firestore + Storage kurallarını deploy et | `firebase deploy --only firestore,storage` |
| 3 | Functions bağımlılıklarını yükle | `cd functions && npm install && cd ..` |
| 4 | Cloud Functions deploy | `firebase deploy --only functions` |

---

## 4. Flutter Ortam Değişkenleri (.env)

Proje kökünde `.env` dosyası olmalı ve aşağıdaki değişkenleri içermeli.

### Bu değerleri nereden alacaksın?

**GoogleService-Info.plist zaten varsa (projede `ios/Runner/GoogleService-Info.plist`):**  
Plist’teki değerleri aşağıdaki eşleştirmeyle proje kökünde `.env` dosyasına yaz:

| .env satırı | Plist’teki key |
|-------------|-----------------|
| `FIREBASE_API_KEY=` | `<key>API_KEY</key>` altındaki `<string>` |
| `FIREBASE_APP_ID=` | `<key>GOOGLE_APP_ID</key>` altındaki `<string>` |
| `FIREBASE_MESSAGING_SENDER_ID=` | `<key>GCM_SENDER_ID</key>` altındaki `<string>` |
| `FIREBASE_PROJECT_ID=` | `<key>PROJECT_ID</key>` altındaki `<string>` |
| `FIREBASE_STORAGE_BUCKET=` | `<key>STORAGE_BUCKET</key>` altındaki `<string>` |
| `FIREBASE_IOS_BUNDLE_ID=` | `<key>BUNDLE_ID</key>` altındaki `<string>` |

Örnek: plist’te `API_KEY` → `AIzaSy...` ise `.env`’de `FIREBASE_API_KEY=AIzaSy...` yaz.

**Plist yoksa:** Firebase Console → [console.firebase.google.com](https://console.firebase.google.com) → Proje (**vestiyer-da67f**) → ⚙️ **Project settings** → **General** → **Your apps** → iOS uygulaması. Oradaki API Key, App ID, Messaging sender ID, Project ID, Storage bucket, Bundle ID değerlerini yukarıdaki .env isimleriyle eşleştir.

| Değişken | Açıklama |
|----------|----------|
| `FIREBASE_API_KEY` | Web/API Key |
| `FIREBASE_APP_ID` | iOS App ID |
| `FIREBASE_MESSAGING_SENDER_ID` | Messaging sender ID |
| `FIREBASE_PROJECT_ID` | Proje ID (örn. vestiyer-da67f) |
| `FIREBASE_STORAGE_BUCKET` | Storage bucket (örn. vestiyer-da67f.firebasestorage.app) |
| `FIREBASE_IOS_BUNDLE_ID` | iOS bundle ID (örn. com.mylmz.vestiyer) |

**.env örneği** (plist’ten kopyalayın; aşağıdaki değerler bu projedeki plist ile uyumludur):
```env
FIREBASE_API_KEY=AIza...
FIREBASE_APP_ID=1:40101973751:ios:d7fdb166a2ba21efca8df2
FIREBASE_MESSAGING_SENDER_ID=40101973751
FIREBASE_PROJECT_ID=vestiyer-da67f
FIREBASE_STORAGE_BUCKET=vestiyer-da67f.firebasestorage.app
FIREBASE_IOS_BUNDLE_ID=com.mylmz.vestiyer
```
(Sadece `FIREBASE_API_KEY` değerini plist’teki `API_KEY` string’i ile değiştirin.)

---

## 5. Test Verisi (İsteğe Bağlı)

| # | Yapılacak | Nasıl |
|---|-----------|--------|
| 1 | **Mock modda test** | `lib/main.dart` içinde `kUseMockBackend = true` yap; Firebase’e bağlanmadan UI test edilir. |
| 2 | **Profil ekranından örnek veri** | Debug modda Profile’da “Test verilerini yükle” butonu ile Firestore’a örnek kıyafet/kombinasyon yazılır. |
| 3 | **Node seed script** | `GOOGLE_APPLICATION_CREDENTIALS=path/to/serviceAccountKey.json node scripts/seed_firestore.js` (Service account key: Firebase Console → Project settings → Service accounts). |

---

## 6. Özet Kontrol Listesi

- [ ] Firebase Console: Email/Password açık, Firestore + Storage oluşturuldu, Blaze plan
- [ ] OPENAI_API_KEY: Secret Manager’da (veya functions config’te) tanımlı
- [ ] `firebase use <projectId>` yapıldı
- [ ] `firebase deploy --only firestore,storage` çalıştırıldı
- [ ] `firebase deploy --only functions` çalıştırıldı
- [ ] `.env` dosyasında tüm FIREBASE_* değişkenleri dolu
- [ ] (İsteğe bağlı) Test kullanıcısı veya mock/seed ile veri yüklendi

Bu adımlar tamamlandığında uygulama canlı Firebase (Auth, Firestore, Storage, Functions) ile çalışır.
