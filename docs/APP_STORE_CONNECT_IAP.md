# App Store Connect — Uygulama İçi Satın Alma Kurulumu

Vestiyer için **Aylık**, **Yıllık** ve **Ömür boyu** ürünlerini App Store Connect’te oluşturma adımları. RevenueCat’teki “default” teklifi bu Product ID’lerle eşleşecek.

---

## 1. Giriş ve uygulamayı açma

1. **https://appstoreconnect.apple.com** → Apple ID ile giriş yap.
2. **Uygulamalar (My Apps)** → **Vestiyer** uygulamasını seç.
3. Sol menüden **Monetizasyon (Monetization)** altında **Uygulama İçi Satın Almalar (In-App Purchases)** veya **Abonelikler (Subscriptions)** bölümüne gir.

---

## 2. Abonelik grubu (Subscription Group) oluşturma

Aylık ve yıllık için otomatik yenilenen abonelik grubu gerekir.

1. **Abonelikler (Subscriptions)** sayfasında **Abonelik Grupları (Subscription Groups)** bölümüne git.
2. **+ (Yeni abonelik grubu)** tıkla.
3. **Referans adı (Reference Name):** `Vestiyer Pro` (sadece senin gördüğün isim).
4. **Oluştur** de.

---

## 3. Aylık abonelik ürünü

1. Oluşturduğun abonelik grubuna gir → **Abonelik ekle (+)**.
2. **Ürün türü:** Otomatik Yenilenen Abonelik (Auto-Renewable Subscription).
3. **Referans adı:** `Vestiyer Pro Aylık`.
4. **Ürün kimliği (Product ID):**  
   `vestiyer_pro_monthly`  
   (Bu ID’yi RevenueCat’te “default” offering’teki Monthly paketine bağlayacaksın. Değiştirirsen RevenueCat’te de aynı ID olmalı.)
5. **Süre:** 1 Ay.
6. **Fiyat:** İstediğin fiyatı seç (örn. Tier veya özel fiyat).
7. **Yerelleştirme:** Türkçe (ve gerekirse İngilizce) görünen ad ve açıklama ekle.
8. **Kaydet**.

---

## 4. Yıllık abonelik ürünü

1. Aynı abonelik grubu içinde tekrar **Abonelik ekle (+)**.
2. **Referans adı:** `Vestiyer Pro Yıllık`.
3. **Ürün kimliği (Product ID):**  
   `vestiyer_pro_annual`
4. **Süre:** 1 Yıl.
5. **Fiyat:** Yıllık fiyatı seç.
6. **Yerelleştirme:** Görünen ad ve açıklama.
7. **Kaydet**.

---

## 5. Ömür boyu (Lifetime) — Tek seferlik satın alma

Apple’da “ömür boyu abonelik” yok; tek seferlik **Tüketilemeyen (Non-Consumable)** ürün kullanılır.

1. Sol menüde **Uygulama İçi Satın Almalar (In-App Purchases)** bölümüne git (Abonelikler’in üst seviyesi veya aynı uygulama altında).
2. **Yönet (Manage)** veya **+ In-App Purchase** tıkla.
3. **Tüketilemeyen (Non-Consumable)** seç → **Oluştur**.
4. **Referans adı:** `Vestiyer Pro Ömür Boyu`.
5. **Ürün kimliği (Product ID):**  
   `vestiyer_pro_lifetime`
6. **Fiyat:** Tek seferlik ömür boyu fiyatı seç.
7. **Yerelleştirme:** Görünen ad ve açıklama.
8. **Kaydet**.

---

## 6. Özet — RevenueCat ile eşleşecek Product ID’ler

| Ürün       | App Store Connect Product ID   | RevenueCat paketi |
|-----------|---------------------------------|-------------------|
| Aylık     | `vestiyer_pro_monthly`         | Monthly (rc_monthly) |
| Yıllık    | `vestiyer_pro_annual`          | Annual (rc_annual)  |
| Ömür boyu| `vestiyer_pro_lifetime`        | Lifetime (rc_lifetime) |

RevenueCat’te **Ürün Kataloğu → Ürünler (Products)** bölümünde her paketin App Store Connect’teki **Product ID** ile aynı kimliği kullandığından emin ol. “Import from App Store Connect” kullanıyorsan bu ID’ler otomatik gelir; manuel ekliyorsan yukarıdaki ID’leri yaz.

---

## 7. Kontrol listesi

- [ ] Abonelik grubu oluşturuldu.
- [ ] Aylık ürün: Product ID `vestiyer_pro_monthly`, süre 1 ay, fiyat ve yerelleştirme dolu.
- [ ] Yıllık ürün: Product ID `vestiyer_pro_annual`, süre 1 yıl, fiyat ve yerelleştirme dolu.
- [ ] Ömür boyu ürün: Product ID `vestiyer_pro_lifetime`, tüketilemeyen, fiyat ve yerelleştirme dolu.
- [ ] RevenueCat’te bu Product ID’lerin “default” offering paketlerine bağlı olduğu doğrulandı.

Metadata ve fiyat değişiklikleri sandbox’ta bazen 1 saate kadar gecikebilir; test ederken bunu göz önünde bulundur.
