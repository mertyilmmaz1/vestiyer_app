# Garment Analysis Pipeline – VPS Plan (Özet)

Bu dosya, `.cursor/plans/` içindeki ana planın VPS odaklı özetidir. VPS bilgilerini verdiğinizde kurulum bu plandaki adımlara göre yapılacak.

---

## Mimari

```
Flutter → Storage (raw) → imageUrl
    ↓
Cloud Function → POST VPS/segment { imageUrl }
    ↓
VPS: rembg remove → crop + normalize → base64 PNG
    ↓
Cloud Function: base64 → Storage (segmentedImageUrl) → color → vision → Firestore
```

---

## VPS Segment Servisi – Gerekli Bilgiler

**Sonraki promptta vermeniz gerekenler:**
- VPS IP veya domain
- SSH erişim bilgileri (veya tercih ettiğiniz deploy yöntemi)
- Docker kullanılacak mı, native Python mı?

**VPS üzerinde kurulacaklar:**
- Python 3.10+
- FastAPI
- rembg (U2Net)
- Pillow
- HTTPS (Let's Encrypt önerilir)

**API:**
- `POST /segment`
- Body: `{ "imageUrl": "https://..." }`
- Response: `{ "success": true, "imageBase64": "data:image/png;base64,..." }`
- Header: `X-API-Key` (Firebase Secret ile aynı)

**Firebase Secrets:**
- `SEGMENT_SERVICE_URL` – VPS API adresi (örn. https://segment.example.com)
- `SEGMENT_SERVICE_API_KEY` – API anahtarı

---

## Cloud Function Değişiklikleri

| Dosya | Değişiklik |
|-------|------------|
| `functions/services/segmentService.js` | Yeni; VPS API çağrısı, timeout 30s, fallback raw |
| `functions/index.js` | Pipeline: callVpsSegment → color → vision |
| `functions/services/colorExtraction.js` | Segmented buffer kabul et |
| `lib/models/clothing.dart` | `segmentedImageUrl` alanı |

---

## Öncelik Sırası

1. **VPS kurulumu** (sizin bilgilerinizle ayrı promptta)
2. segmentService.js + index.js pipeline
3. colorExtraction segmented buffer
4. Firestore/Storage/UI güncellemesi
5. aiService STEP1 prompt güçlendirme
