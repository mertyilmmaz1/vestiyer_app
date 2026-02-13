# Dolap AI - Supabase Veritabanı Şeması ve API Uyumluluğu

## 1. Veritabanı Tabloları

### auth.users
Supabase'in yerleşik kullanıcı tablosu, kullanıcı hesapları ve abonelik bilgilerini depolar.

**Önemli Alanlar**:
- `id`: UUID - Kullanıcının benzersiz kimliği
- `email`: String - Kullanıcının e-posta adresi
- `is_premium`: Boolean - Premium abonelik durumu (varsayılan: false)
- `subscription_start_date`: Timestamp - Aboneliğin başlangıç tarihi
- `subscription_end_date`: Timestamp - Aboneliğin bitiş tarihi
- `subscription_type`: String - Abonelik türü ('monthly', 'yearly')
- `subscription_status`: String - Abonelik durumu ('active', 'expired', 'inactive')
- `free_items_used`: Integer - Kullanılan ücretsiz öğe sayısı
- `last_paywall_shown`: Timestamp - Ödeme duvarının son gösterilme zamanı

### public.clothing_items
Kullanıcıların dolabındaki kıyafet öğelerini depolar.

**Alanlar**:
- `id`: UUID - Öğenin benzersiz kimliği
- `user_id`: UUID - Kıyafetin sahibi olan kullanıcının ID'si (auth.users'a referans)
- `category`: String - Kıyafetin kategorisi (gömlek, pantolon, vb.)
- `main_group`: String - Ana kategori ('üst giyim', 'alt giyim', 'dış giyim', 'ayakkabı', 'aksesuar')
- `color`: String - Kıyafetin rengi
- `material`: String - Kıyafetin malzemesi
- `style`: String - Kıyafetin stili (casual, formal, vb.)
- `season`: String - Uygun sezon(lar)
- `description`: String - Detaylı açıklama
- `image_url`: String - Kıyafet görselinin URL'i
- `created_at`: Timestamp - Ekleme tarihi

### public.outfit_combinations
Kullanıcıların kaydettiği kıyafet kombinlerini depolar.

**Alanlar**:
- `id`: UUID - Kombinin benzersiz kimliği
- `user_id`: UUID - Kombinin sahibi olan kullanıcının ID'si
- `item_ids`: UUID[] - Kombinle ilişkili kıyafet öğelerinin ID'lerinin dizisi
- `created_at`: Timestamp - Oluşturma tarihi

### public.api_usage
AI API kullanımını takip eder.

**Alanlar**:
- `id`: UUID - Kaydın benzersiz kimliği
- `user_id`: UUID - API çağrısını yapan kullanıcının ID'si
- `model`: String - Kullanılan AI modeli (gpt-4-turbo, vb.)
- `prompt_tokens`: Integer - Kullanılan prompt token sayısı
- `completion_tokens`: Integer - Kullanılan tamamlama token sayısı
- `cost`: Numeric - Sorgunun maliyeti
- `timestamp`: Timestamp - İşlem zamanı

### public.subscription_transactions
Abonelik işlemlerini izler.

**Alanlar**:
- `id`: UUID - İşlemin benzersiz kimliği
- `user_id`: UUID - İşlemle ilgili kullanıcının ID'si
- `transaction_id`: String - Harici işlem kimliği
- `transaction_date`: Timestamp - İşlem tarihi
- `provider`: String - Ödeme sağlayıcısı ('apple', 'manual', vb.)
- `subscription_type`: String - Abonelik türü ('monthly', 'yearly', 'cancelled')
- `amount`: Numeric - İşlem tutarı
- `status`: String - İşlem durumu ('completed', 'cancelled', vb.)
- `details`: JSONB - Ek bilgiler

## 2. Veritabanı Tetikleyicileri (Triggers)

### update_subscription_status
**Tablolar**: auth.users
**Olaylar**: INSERT, UPDATE
**İşlev**: Abonelik bitiş tarihini kontrol eder ve premium durumunu otomatik olarak günceller.

```sql
CREATE OR REPLACE FUNCTION update_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
    -- If subscription has expired, set status to expired and premium to false
    IF (NEW.subscription_end_date IS NOT NULL AND NEW.subscription_end_date < CURRENT_TIMESTAMP) THEN
        NEW.is_premium = FALSE;
        NEW.subscription_status = 'expired';
    -- If subscription is active and end date is in the future
    ELSIF (NEW.is_premium = TRUE AND 
          (NEW.subscription_end_date IS NULL OR NEW.subscription_end_date > CURRENT_TIMESTAMP)) THEN
        NEW.subscription_status = 'active';
    -- If no subscription
    ELSIF (NEW.is_premium = FALSE) THEN
        NEW.subscription_status = 'inactive';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

### update_free_items_count
**Tablolar**: public.clothing_items
**Olaylar**: INSERT, DELETE
**İşlev**: Kullanıcının kıyafet öğeleri eklendiğinde veya silindiğinde free_items_used sayısını günceller.

```sql
CREATE OR REPLACE FUNCTION update_free_items_count()
RETURNS TRIGGER AS $$
DECLARE
    items_count INTEGER;
BEGIN
    -- Count user's clothing items
    SELECT COUNT(*) INTO items_count 
    FROM public.clothing_items 
    WHERE user_id = NEW.user_id;
    
    -- Update the free_items_used count in users table if not premium
    UPDATE auth.users 
    SET free_items_used = items_count
    WHERE id = NEW.user_id AND is_premium = FALSE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

## 3. API Erişim Modeli

API'lar, Supabase'in Row Level Security (RLS) kurallarını kullanarak veri erişimini güvenli hale getirir:

- **Kimlik Doğrulama**: Tüm API çağrıları `Authorization` başlığında geçerli bir JWT gerektirir
- **Veri Erişimi**: Kullanıcılar yalnızca kendi verilerine erişebilir (user_id = auth.uid())
- **Servis Rolü**: Edge Functions, yönetici işlevleri için service_role anahtarını kullanır

## 4. Önemli API Uç Noktaları

### Edge Functions

#### /analyze-and-save-clothing
Bir kıyafet görselini analiz eder ve veritabanına kaydeder. Free/premium kullanıcı kontrolü yapar.

#### /manage-premium-status
Bir kullanıcının premium durumunu günceller. Yalnızca admin rolüne sahip kullanıcılar tarafından çağrılabilir.

### Supabase Client API Kullanımı

#### Auth İşlemleri
```dart
// Oturum açma
final response = await supabase.auth.signInWithPassword(email: email, password: password);

// Kayıt olma
final response = await supabase.auth.signUp(email: email, password: password);

// Oturumu kapatma
await supabase.auth.signOut();
```

#### Kullanıcı Verileri
```dart
// Kullanıcı abonelik durumunu sorgulama
final response = await supabase
    .from('auth.users')
    .select('is_premium, subscription_end_date, subscription_type, free_items_used')
    .eq('id', userId)
    .single();
```

#### Kıyafet İşlemleri
```dart
// Kıyafet ekleme
await supabase.from('clothing_items').insert({
  'user_id': userId,
  'category': item.category,
  'description': item.description,
  'image_url': imageUrl,
  'main_group': item.mainGroup,
  // Diğer alanlar...
});

// Kıyafetleri listeleme
final response = await supabase
    .from('clothing_items')
    .select()
    .eq('user_id', userId)
    .order('created_at', ascending: false);
```

## 5. Uyumluluk Değişiklikleri

Aşağıdaki değişiklikler API'ları Supabase şemasıyla uyumlu hale getirmiştir:

1. `users` -> `auth.users` geçişi
2. `subscriptions` tablosunun kaldırılması, abonelik bilgilerinin direkt `auth.users` içinde tutulması
3. Premium kontrolleri `auth.users` tablosundan ve abonelik bitiş tarihini de dikkate alarak yapılıyor
4. Otomatik subscription_status güncellemeleri için tetikleyiciler eklendi
5. Kıyafet sayısı güncellemeleri için otomatik tetikleyiciler eklendi

Bu şema ve API düzenlemeleri, Dolap AI uygulamasının Supabase veritabanı alt yapısıyla tam uyumlu çalışmasını sağlar. 