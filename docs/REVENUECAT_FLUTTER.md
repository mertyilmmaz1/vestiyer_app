# RevenueCat Entegrasyonu (Flutter)

Uygulama, **vestiyer Pro** yetkisi (entitlement) ile abonelikler için RevenueCat kullanır. **Paywall ekranı kendi tasarımımız** (PremiumScreen + PaywallWidget); RevenueCat sadece fiyat/satın alma motoru ve yetki kontrolü için kullanılıyor.

## Kendi paywall’ını kullanma (mevcut yapı)

- **Görünen ekran**: Senin oluşturduğun PremiumScreen (plan seçici, özellik listesi, fiyat, “PREMIUM’A GEÇ” butonu) ve gerektiğinde açılan PaywallWidget bottom sheet.
- **RevenueCat’in rolü**:  
  - Fiyatları ve paketleri getirmek: `getOfferings()` → `current.monthly`, `current.annual`, `current.lifetime` ve her paketin `storeProduct.priceString`.  
  - Satın almayı yapmak: “PREMIUM’A GEÇ”e basıldığında `purchaseSubscription(seçilen plan)` veya `purchasePackage(package)` çağrılıyor.  
  - Yetki kontrolü: `vestiyer Pro` entitlement ile `isPremium` durumu.
- RevenueCat’in hazır paywall ekranı (`RevenueCatUI.presentPaywall`) **kullanılmıyor**; tasarım tamamen senin ekranında.
- **RevenueCat’e “paywall aktarma”**: RevenueCat panelindeki Paywalls aracı, kendi hazır şablon ekranı için. Flutter’daki özel ekranını oraya “aktarıp” gösterme imkânı yok. İki seçenek: (1) Kendi paywall’ın + RevenueCat sadece backend (şu anki yapı). (2) RevenueCat’in hazır paywall’ını kullanırsan, tasarımı RevenueCat dashboard’da yaparsın; Flutter’da sadece `presentPaywall()` çağrısı kalır.

## 1. Kurulum (zaten yapılmış)

```bash
flutter pub add purchases_flutter purchases_ui_flutter
```

- **purchases_flutter**: Çekirdek SDK (yapılandırma, giriş, teklifler, satın alma, geri yükleme, müşteri bilgisi). Kendi paywall’ında fiyat ve satın alma için bunu kullanıyoruz.
- **purchases_ui_flutter**: Sadece **Müşteri Merkezi** (Customer Center) için kullanılıyor; Profil’deki “Aboneliği yönet” bu ekranı açar. RevenueCat’in hazır paywall ekranı kullanılmıyor.

Kaynak: [RevenueCat Flutter Kurulum](https://www.revenuecat.com/docs/getting-started/installation/flutter#installation).

## 2. Yapılandırma ve API anahtarı

- **Tek anahtar (örn. test)**: `.env` dosyasına `REVENUECAT_API_KEY` yazın. Hem iOS hem Android’de kullanılır.
- **Canlı (production)**: `.env` içinde `REVENUECAT_APPLE_API_KEY` ve `REVENUECAT_GOOGLE_API_KEY` tanımlayın.

Test için `.env` örneği:

```env
REVENUECAT_API_KEY=test_utLXYYPdlyrgnfWxwhJSCYWXfmS
```

Yapılandırma `lib/services/revenuecat_init_io.dart` içinde çalışır (sadece iOS/Android). Web’de `revenuecat_init_stub.dart` kullanılır (işlem yapmaz). Mock backend (`kUseMockBackend`) açıkken RevenueCat atlanır.

## 3. Başlatma

- **Uygulama açılışı**: `ApplicationInitialize.make()`, Firebase’den sonra `configureRevenueCat()` çağırır.
- **Giriş sonrası**: Kullanıcıya bağlı yetkiler için `revenueCatLogIn(firebaseUid)` çağrılır.

## 4. Yetki (entitlement): vestiyer Pro

- Yetki ID’si: `kPremiumEntitlementId` = `'vestiyer Pro'` (RevenueCat panelindeki isimle birebir aynı olmalı).
- **SubscriptionProvider**, `Purchases.addCustomerInfoUpdateListener` ile dinler ve yetkiyi `isPremium`, `subscriptionEndDate`, `subscriptionType` alanlarına uygular.

## 5. Ürünler (Offerings)

RevenueCat panelinde tanımlayın:

- **Aylık** – `PackageType.monthly` (örn. identifier: `monthly`).
- **Yıllık** – `PackageType.annual` (örn. identifier: `yearly`).
- **Ömür boyu** – `PackageType.lifetime` (örn. identifier: `lifetime`).

Uygulama **mevcut teklifi** `Purchases.getOfferings()?.current` ile alır. PremiumScreen’de seçilen plana göre `current.monthly`, `current.annual` veya `current.lifetime` paketinin fiyatı (`package.storeProduct.priceString`) gösterilir.

## 6. Abonelik akışı (kendi paywall ile)

- **PremiumScreen**: Plan seçici (Aylık / Yıllık / Ömür boyu) → “PREMIUM’A GEÇ”e basıldığında doğrudan `purchaseSubscription(seçilen plan)` çağrılır (RevenueCat’in ekranı açılmaz).
- **PaywallWidget.showPaywall()**: Bottom sheet’te “Yükselt”e basılınca kullanıcı **PremiumScreen**’e (kendi paywall’ına) gider; orada plan seçip satın alır.
- **Satın alma**: `SubscriptionProvider.purchaseSubscription(SubscriptionType.monthly|yearly|lifetime)` veya `purchasePackage(package)`.
- **Geri yükleme**: PremiumScreen ve bottom sheet’te “Satın alımları geri yükle” → `SubscriptionProvider.restorePurchases()`.
- **Hatalar**: `purchasePackageWithResult(package)` ile `PurchaseResult`; kullanıcıya mesaj için `lastPurchaseErrorMessage`.

## 7. RevenueCat hazır paywall (bu projede kullanılmıyor)

Kendi paywall’ını kullandığımız için `RevenueCatUI.presentPaywall()` çağrılmıyor. İleride RevenueCat’in hazır ekranına geçmek istersen: [RevenueCat Paywalls](https://www.revenuecat.com/docs/tools/paywalls) ile dashboard’da tasarım yapıp Flutter’da `RevenueCatUI.presentPaywall(offering: ...)` kullanabilirsin.

## 8. Müşteri Merkezi (Customer Center)

- **Gösterme**: `RevenueCatUI.presentCustomerCenter()` (örn. premium kullanıcılar için Profil ekranından).
- Kullanıcı aboneliği yönetir, satın alımları geri yükler. Bkz. [Customer Center](https://www.revenuecat.com/docs/tools/customer-center).

## 9. Müşteri bilgisi ve iyi uygulamalar

- **Müşteri bilgisi**: Hata ayıklama veya özel mantık için ham `CustomerInfo?` almak üzere `SubscriptionProvider.getCustomerInfo()` kullanılır.
- **Doğru kaynak**: Yetki bilgisinin kaynağı RevenueCat’tir; sunucu/Cloud Functions için Firestore kullanıcı dokümanında `isPremium` aynalanabilir.
- **Log**: `kDebugMode` true iken `configureRevenueCat()` içinde debug log açılır.
- **Çevrimdışı**: İnternet yokken önbelleğe alınmış müşteri bilgisi kullanılır; güncellemek için `refreshSubscriptionStatus()` veya satın alma/geri yükleme sonrası yenileme yapın.

## 10. Dosya referansı

| Dosya | Görevi |
|-------|--------|
| `lib/services/revenuecat_init.dart` | Stub/IO export |
| `lib/services/revenuecat_init_io.dart` | Yapılandırma + giriş (.env’den API anahtarları) |
| `lib/services/revenuecat_init_stub.dart` | Web’de işlem yok |
| `lib/providers/subscription_provider.dart` | Yetki durumu, teklifler, satın alma, geri yükleme, müşteri bilgisi dinleyicisi |
| `lib/screens/premium_screen.dart` | Kendi paywall: plan seçimi, fiyat (RevenueCat’ten), satın alma butonu |
| `lib/widgets/paywall_widget.dart` | Bottom sheet paywall girişi → PremiumScreen’e yönlendirme |
| `lib/screens/profile_screen.dart` | “Aboneliği yönet” → Müşteri Merkezi |
