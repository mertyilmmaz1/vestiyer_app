# Vestiyer

AI destekli kişisel gardırop yönetimi ve stil danışmanı mobil uygulaması.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase" alt="Firebase" />
  <img src="https://img.shields.io/badge/OpenAI-GPT--4-412991?logo=openai" alt="OpenAI" />
</p>

---

## Özellikler

- **Gardırop Yönetimi** — Kıyafetlerinizi fotoğraflayarak ekleyin, kategorilere göre düzenleyin
- **AI Kıyafet Analizi** — Yüklediğiniz kıyafetler GPT-4 Vision ile otomatik analiz edilir (kategori, renk, kumaş, mevsim, tarz)
- **AI Stilist** — Dolabınızdaki kıyafetlerden kişiselleştirilmiş kombin önerileri alın
- **Gardırop Analizi** — Dolabınızın genel yapısını ve eksiklerini görün
- **Premium Abonelik** — Sınırsız kıyafet ve AI önerileri için premium üyelik
- **API Kullanım Takibi** — AI kullanımınızı ve maliyetlerinizi takip edin

---

## Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| **Mobil** | Flutter (Dart 3.2+) |
| **Backend** | Firebase (Auth, Firestore, Storage, Cloud Functions) |
| **AI** | OpenAI GPT-4o (Vision + Chat) |
| **State Management** | Provider |
| **Görsel İşleme** | image_picker, flutter_image_compress, cached_network_image |

---

## Proje Yapısı

```
├── lib/
│   ├── models/           # Veri modelleri (clothing, user, combination)
│   ├── providers/        # WardrobeProvider, SubscriptionProvider
│   ├── screens/          # Uygulama ekranları
│   ├── services/         # Firebase, Firestore, Storage, Cloud Functions
│   │   └── mock/         # Mock servisler (Firebase olmadan test)
│   ├── widgets/          # Paywall, occasion selection
│   └── main.dart
├── functions/            # Firebase Cloud Functions (Node.js)
│   ├── index.js          # analyzeClothing, generateCombinations, getStyleAdvice
│   └── services/
│       └── aiService.js  # OpenAI entegrasyonu
├── supabase/             # Alternatif backend (Edge Functions, migrations)
├── firestore.rules       # Firestore güvenlik kuralları
├── storage.rules         # Storage güvenlik kuralları
└── FIREBASE_YAPILACAKLAR.md  # Firebase kurulum rehberi
```

---

## Kurulum

### Gereksinimler

- Flutter SDK 3.2+
- Node.js 20+ (Cloud Functions için)
- Firebase CLI
- Firebase projesi (Blaze plan — Functions için)

### 1. Bağımlılıkları yükle

```bash
flutter pub get
```

### 2. Ortam değişkenleri

Proje kökünde `.env` dosyası oluşturun:

```env
FIREBASE_API_KEY=your_api_key
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_STORAGE_BUCKET=your_storage_bucket
FIREBASE_IOS_BUNDLE_ID=com.example.vestiyer
```

Değerleri Firebase Console → Project settings → Your apps üzerinden alabilirsiniz.

### 3. Firebase kurulumu

Detaylı adımlar için [FIREBASE_YAPILACAKLAR.md](FIREBASE_YAPILACAKLAR.md) dosyasına bakın.

Özet:

```bash
# Firebase projesini seç
firebase use <project-id>

# Firestore ve Storage kurallarını deploy et
firebase deploy --only firestore,storage

# Cloud Functions
cd functions && npm install && cd ..
firebase deploy --only functions
```

### 4. OpenAI API Key

Cloud Functions için `OPENAI_API_KEY` gerekli:

- **Secret Manager:** Google Cloud Console → Secret Manager → `OPENAI_API_KEY` oluştur
- Functions deploy sırasında otomatik kullanılır (`secrets: ['OPENAI_API_KEY']`)

---

## Çalıştırma

### Mock mod (Firebase olmadan)

`lib/main.dart` içinde:

```dart
const bool kUseMockBackend = true;  // Firebase kullanılmaz
```

```bash
flutter run
```

### Gerçek Firebase ile

```dart
const bool kUseMockBackend = false;
```

```bash
flutter run
```

---

## Cloud Functions

| Fonksiyon | Açıklama |
|-----------|----------|
| `analyzeClothing` | Kıyafet fotoğrafını GPT-4 Vision ile analiz eder, Firestore'a kaydeder |
| `generateCombinations` | Dolabınızdan kombin önerileri oluşturur |
| `getStyleAdvice` | Stil danışmanı sohbeti |
| `managePremiumStatus` | Premium abonelik durumunu günceller |

---

## Lisans

Bu proje özel kullanım içindir.

---

## Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Commit edin (`git commit -m 'Yeni özellik eklendi'`)
4. Push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request açın
