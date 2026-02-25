# Firebase Deploy

`functions/` klasöründe değişiklik yaptıktan sonra production'a deploy et.

## Sadece Cloud Functions:
```bash
firebase deploy --only functions
```

## Belirli bir function:
```bash
firebase deploy --only functions:analyzeClothing
firebase deploy --only functions:generateCombinations
firebase deploy --only functions:getStyleAdvice
firebase deploy --only functions:managePremiumStatus
```

## Tüm Firebase kaynakları (Functions + Firestore rules + Storage rules):
```bash
firebase deploy
```

## Deploy öncesi kontrol listesi:
- [ ] `functions/` altındaki değişiklikler kaydedildi
- [ ] `npm install` çalıştırıldı (yeni paket eklendiyse)
- [ ] Yerel emülatörde test edildi
- [ ] `.env` dosyasındaki environment variable'lar production'da set edildi

## Emülatör ile test:
```bash
firebase emulators:start
# Belirli servisleri başlat:
firebase emulators:start --only functions,firestore,auth
```
