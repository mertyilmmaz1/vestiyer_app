# Yeni Cloud Function Şablonu

Firebase Cloud Functions'a yeni bir callable function eklemek için adımlar.

## 1. `functions/index.js`'e Ekle

```javascript
exports.myNewFunction = onCall(
  { region: 'us-central1', enforceAppCheck: false },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError('unauthenticated', 'Authentication required');
    }

    const { param1, param2 } = request.data;

    // Girdi doğrula
    if (!param1) {
      throw new HttpsError('invalid-argument', 'param1 is required');
    }

    try {
      // İş mantığı...
      const result = await someService.doSomething(param1, param2);
      return { success: true, data: result };
    } catch (error) {
      console.error('myNewFunction error:', error);
      throw new HttpsError('internal', 'Operation failed');
    }
  }
);
```

## 2. Flutter Client'a Ekle

`lib/services/cloud_functions_service.dart`:
```dart
Future<Map<String, dynamic>> myNewFunction({
  required String param1,
  String? param2,
}) async {
  try {
    final result = await _functions.httpsCallable('myNewFunction').call({
      'param1': param1,
      'param2': param2,
    });
    return Map<String, dynamic>.from(result.data);
  } on FirebaseFunctionsException catch (e) {
    throw Exception('myNewFunction failed: ${e.message}');
  }
}
```

## 3. FirestoreServiceBase'e Ekle (gerekirse)

```dart
// lib/services/firestore_service_base.dart
Future<void> myNewOperation(String userId, Map<String, dynamic> data);

// lib/services/cached_firestore_service.dart — read-through veya invalidate
// lib/services/mock/mock_firestore_service.dart — mock implementasyon
```

## 4. Deploy

```bash
firebase deploy --only functions:myNewFunction
```

## Kontrol Listesi

- [ ] Auth kontrolü yapıldı (`request.auth?.uid`)
- [ ] Girdi doğrulaması var
- [ ] OpenAI / secret key'ler `process.env` ile alınıyor
- [ ] Hata mesajları kullanıcıya anlamlı
- [ ] Flutter mock servisi güncellendi (`MockCloudFunctionsService`)
- [ ] Deploy yapıldı: `firebase deploy --only functions`
