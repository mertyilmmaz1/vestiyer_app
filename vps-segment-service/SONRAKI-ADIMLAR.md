# VPS segment servisi – Sonraki adımlar (ne yapacaksın)

VPS kuruldu, servis çalışıyor. Şimdi Firebase tarafını bağlaman gerekiyor.

---

## 1. Firebase’de secret’ları tanımla

Cloud Functions’ın VPS’e istek atabilmesi için iki secret gerekli.

**Firebase CLI ile (terminalde proje kökündeyken):**

```bash
cd /Users/mertyilmaz/Documents/GitHub/vestiyer_app/vestiyer_app

# VPS adresi (port 8000)
firebase functions:secrets:set SEGMENT_SERVICE_URL
# Sorulunca yaz: http://31.97.45.46:8000

# API anahtarı (VPS’teki ile aynı olmalı)
firebase functions:secrets:set SEGMENT_SERVICE_API_KEY
# Sorulunca yaz: vestiyer-segment-key-degistirin
```

VPS’te farklı bir API anahtarı kullandıysan, onu yaz. VPS’teki anahtarı görmek için sunucuda: `cat /etc/segment-service/api_key.env`

---

## 2. Cloud Functions’ı deploy et

```bash
cd /Users/mertyilmaz/Documents/GitHub/vestiyer_app/vestiyer_app
firebase deploy --only functions
```

Bu komut `analyzeClothing` ve diğer fonksiyonları günceller; secret’lar otomatik enjekte edilir.

---

## 3. Test et

Uygulamada bir kıyafet fotoğrafı ekle (analiz et). Arka plan VPS’te temizlenip analiz segmentli görsel üzerinden yapılacak. Hata alırsan Firebase Console → Functions → Logs’tan `analyzeClothing` loglarına bak.

---

## Özet

| # | Ne yapacaksın | Komut / işlem |
|---|----------------|----------------|
| 1 | Secret: VPS URL | `firebase functions:secrets:set SEGMENT_SERVICE_URL` → `http://31.97.45.46:8000` |
| 2 | Secret: API key | `firebase functions:secrets:set SEGMENT_SERVICE_API_KEY` → VPS’teki anahtar |
| 3 | Deploy | `firebase deploy --only functions` |
| 4 | Test | Uygulamada kıyafet ekle / analiz et |

Bu adımlardan sonra pipeline: **Foto yükle → Cloud Function → VPS segment → Storage’a segment kaydet → Renk + Vision analiz → Firestore** şeklinde çalışır.
