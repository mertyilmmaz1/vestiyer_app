# Mock Mod

`kUseMockBackend` flag'i ile Firebase/RevenueCat/Hive'ı bypass et.

## Mock Modu Aç

`lib/core/product/init/application_initialize.dart` dosyasında:
```dart
const kUseMockBackend = true;
```

Mock modda:
- Firebase init atlanır
- RevenueCat init atlanır
- Hive init atlanır
- Şu mock servisler kullanılır:
  - `MockFirebaseAuthService`
  - `MockFirestoreService`
  - `MockCloudFunctionsService`
  - `MockFirebaseStorageService`

## Mock Modu Kapat (Production/Real Backend)

```dart
const kUseMockBackend = false;
```

## Mock Kullanıcı Oturumu

Mock modda oturum açmak için `mockSignedInNotifier` değerini `true` yapın.

## Mock Veri

Mock veri için `lib/utils/mock_data_helper.dart` dosyasını düzenleyin.

## Ne Zaman Mock Kullanılır?

- Firebase bağlantısı olmadan UI geliştirmesi
- Birim testleri
- CI/CD pipeline'da
- Hızlı prototipleme
