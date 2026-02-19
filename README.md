# Vestiyer — AI-Powered Wardrobe Assistant

**Flutter ile geliştirilmiş, yapay zeka destekli kişisel gardırop ve stil danışmanı mobil uygulaması.**  
Kullanıcılar kıyafetlerini fotoğraflayıp yükleyebilir, otomatik analiz ve kombin önerileri alabilir; premium abonelik ile sınırsız AI özelliklerine erişebilir.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart" alt="Dart" />
  <img src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase" alt="Firebase" />
  <img src="https://img.shields.io/badge/OpenAI-GPT--4o-412991?logo=openai" alt="OpenAI" />
</p>

---

## Proje Özeti (Portfolyo)

Bu proje, **mobil (Flutter)**, **backend (Firebase + Cloud Functions)** ve **AI (OpenAI)** entegrasyonunu tek bir ürün içinde bir araya getiren tam yığın bir örnektir. İş başvurularında referans olarak kullanılmak üzere hazırlanmıştır.

| Alan | Kullanılan Teknolojiler |
|------|-------------------------|
| **Frontend** | Flutter, Provider (state management), Material/Cupertino |
| **Auth & Veri** | Firebase Auth (e-posta, Google, Apple), Firestore, Storage |
| **Backend** | Firebase Cloud Functions (Node.js), callable functions |
| **AI** | OpenAI GPT-4o (Vision + Chat) — sadece sunucu tarafında, API anahtarı client’ta tutulmaz |
| **Ödeme** | RevenueCat — abonelik ve paywall |
| **Opsiyonel** | VPS üzerinde Python/FastAPI ile arka plan kaldırma (segment) servisi |

**Öne çıkan noktalar:**

- **Güvenlik:** Tüm hassas anahtarlar (OpenAI, Firebase config) ortam değişkenleri veya Firebase Secrets ile yönetilir; `.env` ve Firebase config dosyaları repoda yer almaz.
- **Mimari:** Cloud Functions ile AI çağrıları, mock backend ile Firebase olmadan test, Hive ile Firestore read-through cache.
- **Ürün özellikleri:** Gardırop yönetimi, AI kıyafet analizi, kombin önerileri, stil danışmanı sohbeti, premium abonelik akışı.

---

## Özellikler

- **Gardırop yönetimi** — Kıyafetleri fotoğrafla ekleme, kategorilere göre listeleme ve filtreleme
- **AI kıyafet analizi** — Yüklenen görsellerin GPT-4 Vision ile otomatik analizi (kategori, renk, kumaş, mevsim, tarz)
- **Kombin önerileri** — Dolaptaki parçalardan kişiselleştirilmiş kombin önerileri
- **Vestiyer Asistanı** — Stil danışmanı sohbeti (premium)
- **Gardırop analizi** — Dolap özeti ve eksik parça önerileri
- **Premium abonelik** — RevenueCat ile abonelik ve paywall; sınırsız AI kullanımı
- **API kullanım takibi** — AI kullanımı ve kota bilgisi

---

## Teknoloji Yığını

| Katman | Teknoloji |
|--------|-----------|
| **Mobil** | Flutter (Dart 3.2+), Provider |
| **Backend** | Firebase (Auth, Firestore, Storage, Cloud Functions) |
| **AI** | OpenAI GPT-4o (Vision + Chat) — Cloud Functions üzerinden |
| **Ödeme** | RevenueCat |
| **Görsel / cache** | image_picker, flutter_image_compress, cached_network_image, Hive |
| **Opsiyonel segment** | VPS: Python, FastAPI, rembg (U2Net) |

---

## Proje Yapısı

```
├── lib/
│   ├── core/              # Tema, başlatma, ortak widget'lar
│   ├── models/            # Veri modelleri (clothing, user, combination)
│   ├── providers/         # WardrobeProvider, SubscriptionProvider
│   ├── screens/           # Tüm uygulama ekranları
│   ├── services/          # Firebase, Firestore, Storage, Cloud Functions, cache
│   │   └── mock/          # Mock servisler (Firebase olmadan test)
│   ├── widgets/           # Paywall, occasion selection, ortak UI
│   └── main.dart
├── functions/             # Firebase Cloud Functions (Node.js)
│   ├── index.js           # analyzeClothing, generateCombinations, getStyleAdvice, vb.
│   └── services/
│       └── aiService.js   # OpenAI entegrasyonu
├── vps-segment-service/   # Opsiyonel: arka plan kaldırma (Python/FastAPI)
├── firestore.rules
├── storage.rules
├── .env.example           # Örnek ortam değişkenleri (gerçek .env repoda yok)
└── README.md
```

---

## Kurulum

### Gereksinimler

- Flutter SDK 3.2+
- Node.js 20+ (Cloud Functions için)
- Firebase CLI
- Firebase projesi (Blaze plan — Cloud Functions için)

### 1. Bağımlılıkları yükle

```bash
flutter pub get
cd functions && npm install && cd ..
```

### 2. Ortam değişkenleri (gizli bilgiler repoda yok)

Proje kökünde `.env` dosyası oluşturun; şablon için `.env.example` kullanın:

```bash
cp .env.example .env
# .env içine Firebase, (opsiyonel) Google Web Client ID vb. değerleri girin.
```

Firebase config değerleri: **Firebase Console → Project settings → Your apps**.  
**Not:** `GoogleService-Info.plist` ve `google-services.json` güvenlik nedeniyle repoda bulunmaz; kendi Firebase projenizden indirip ilgili klasörlere eklemeniz gerekir.

### 3. Firebase kurulumu

```bash
firebase use <project-id>
firebase deploy --only firestore,storage
firebase deploy --only functions
```

Cloud Functions için `OPENAI_API_KEY` gerekir: **Google Cloud Secret Manager** ile tanımlanır; Functions `secrets: ['OPENAI_API_KEY']` ile kullanır.

### 4. Çalıştırma

**Mock mod (Firebase olmadan test):**  
`lib/core/product/init/application_initialize.dart` içinde `kUseMockBackend = true` yapın.

```bash
flutter run
```

**Gerçek backend ile:**  
`kUseMockBackend = false` ve geçerli `.env` + Firebase config ile:

```bash
flutter run
```

---

## Cloud Functions (Özet)

| Fonksiyon | Açıklama |
|-----------|----------|
| `analyzeClothing` | Kıyafet fotoğrafını GPT-4 Vision ile analiz eder, Firestore’a kaydeder |
| `generateCombinations` | Dolaptan kombin önerileri üretir |
| `getStyleAdvice` | Stil danışmanı sohbeti (Vestiyer Asistanı) |
| `managePremiumStatus` | Premium abonelik durumunu günceller |

Segment (arka plan kaldırma) isteğe bağlıdır; VPS’te çalışan ayrı bir servise yönlendirilir.

---

## Güvenlik (Public Repo)

Bu depo public paylaşım için hazırdır. Aşağıdakiler **asla** commit edilmez (`.gitignore` ile hariç tutulmuştur):

- `.env` ve diğer ortam dosyaları (sadece `.env.example` şablon olarak bulunur)
- `GoogleService-Info.plist`, `google-services.json`
- Firebase Admin SDK / service account anahtarları
- Android keystore / imza dosyaları
- VPS şifreleri veya API anahtarları

**Önemli:** Repo daha önce private iken bu dosyalardan biri commit edildiyse, repoyu public yapmadan önce git geçmişinden kaldırın (örn. `git filter-repo` veya BFG Repo-Cleaner). Firebase Console’dan yeni bir API anahtarı oluşturup eski anahtarı devre dışı bırakmanız da önerilir.

---

## Lisans

Bu proje portfolyo ve eğitim amaçlı paylaşılmaktadır.

---

## İletişim

Sorularınız veya geri bildiriminiz için GitHub üzerinden iletişime geçebilirsiniz.
