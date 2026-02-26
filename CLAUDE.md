# Vestiyer (Dolap AI) — Claude Code Rehberi

## Proje Özeti

Flutter ile geliştirilmiş yapay zeka destekli kişisel gardrop asistanı. Kullanıcılar kıyafetlerini analiz ettirir, kombin oluşturur ve stil önerileri alır.

## Teknoloji Yığını

- **Frontend**: Flutter, Provider (state management)
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions)
- **AI**: GPT-4o (kıyafet analizi - vision), GPT-4o-mini (kombinler, sohbet)
- **Abonelik**: RevenueCat (iOS/Android), stub (web)
- **Cache**: Hive (read-through, CachedFirestoreService)

## Dizin Yapısı

```
lib/
  core/           # Tema (AppTheme, AppColors), init (ApplicationInitialize), Vestiyer UI bileşenleri
  models/         # Clothing, Combination, User, OutfitLog, ApiUsage
  providers/      # WardrobeProvider, SubscriptionProvider
  screens/        # Tüm ekranlar
  services/       # Firebase Auth, Firestore, Storage, CloudFunctions, cache, RevenueCat
  widgets/        # Tekrar kullanılabilir UI bileşenleri
  utils/          # Yardımcı fonksiyonlar
functions/        # Firebase Cloud Functions (Node.js/OpenAI)
  services/       # aiService.js, combinationEngine.js, colorExtraction.js, vb.
```

## Mimari Kurallar

### Servis Katmanı
- Tüm Firestore erişimi **FirestoreServiceBase** üzerinden: `CachedFirestoreService(FirestoreService(), HiveCacheService)`
- Ekranlar ve provider'lar asla `FirestoreService`'e doğrudan bağlanmaz
- Yeni Firestore operasyonu eklenince `FirestoreServiceBase` → `CachedFirestoreService` zinciri güncellenir

### Cache (Hive Read-Through)
- **Okuma**: Önce Hive cache'e bak; miss'te delegate çağır, sonucu cache'e yaz
- **Yazma**: Önce delegate'e yaz, sonra ilgili cache key'i invalidate et
- **Stream'ler** (`clothingStream`, `combinationsStream`): Cache'e alınmaz, delegate'e pass-through
- Cache key prefix'leri: `user_`, `clothing_`, `clothing_item_`, `combinations_`

### AI Entegrasyonu
Tüm AI çağrıları Cloud Functions üzerinden — Flutter tarafında OpenAI key YOK:
- `analyzeClothing` → GPT-4o vision (quality check → k-means color → two-step AI → Firestore)
- `generateCombinations(occasion)` → mode: `full`/`limited`/`styling`; styling modda `stylingAdvice` döner, Firestore'a kaydedilmez
- `getStyleAdvice` → GPT-4o-mini sohbet (premium)
- `managePremiumStatus` → sunucu tarafı abonelik mantığı

### Platform & Init
Başlatma sırası (`ApplicationInitialize`):
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `dotenv.load()`
3. `Firebase.initializeApp()`
4. `SystemChrome` ayarları
5. `configureRevenueCat()` — stub/web'de no-op
6. `Hive.initFlutter()` + `HiveCacheService.init()`

RevenueCat conditional import: `revenuecat_init_stub.dart` if web, `revenuecat_init_io.dart` if dart.library.io

## Firestore Koleksiyonları

```
users/{uid}
users/{uid}/clothing/{clothingId}
users/{uid}/combinations/{combinationId}
users/{uid}/outfit_logs/{logId}
```

## Navigasyon

`main.dart` → `SplashScreenWrapper` → auth state'e göre `OnboardingScreen` veya `_AuthenticatedHome`
`_AuthenticatedHome`: IndexedStack tabs — Home, Wardrobe, Upload (push), AI Stylist, Profile

## UI Konvansiyonlar

- Vestiyer bileşenleri: `VestiyerPageHeader`, `VestiyerCard`, `VestiyerPrimaryButton`, `VestiyerTextField`, `VestiyerDivider`, `VestiyerBackButton`
- Renkler: `AppColors`, tipografi: `AppTheme.darkTheme`
- Görseller: `cached_network_image` (Storage URL'leri için)
- Loading/error durumları her callable ve Firestore işleminde gösterilmeli

## Premium / Abonelik

- RevenueCat entitlement = kaynak of truth; Firestore user doc'a (`isPremium`, `premiumStartDate`, `premiumEndDate`) sync edilir
- `SubscriptionProvider` RevenueCat customer info dinler
- Premium özellikler: Vestiyer Asistanı (getStyleAdvice), AssistantChatScreen
- Paywall: `PremiumScreen`, `PaywallWidget`

## Güvenlik Kuralları

- API key'ler sadece Cloud Functions ortam değişkenlerinde (`.env`) — client'ta ASLA
- Firestore/Storage kuralları `request.auth.uid` bazlı
- Cloud Functions'ta girdi doğrula

## Deploy

Cloud Functions değiştiğinde **production'a otomatik yansımaz**:

```bash
firebase deploy --only functions
```

`functions/` altında değişiklik yapıldığında kullanıcıya hatırlat: `firebase deploy --only functions` çalıştırmaları gerekiyor.

## Sık Kullanılan Komutlar

```bash
# Flutter
flutter pub get
flutter run
flutter build apk --release
flutter build ipa --release

# Firebase Functions deploy
firebase deploy --only functions

# Emülatör
firebase emulators:start

# Functions tek tek deploy
firebase deploy --only functions:analyzeClothing
```

## Slash Komutları (Proje)

- `/project:deploy` — Firebase deploy rehberi
- `/project:new-screen` — Yeni ekran oluşturma şablonu
- `/project:new-function` — Yeni Cloud Function ekleme şablonu
