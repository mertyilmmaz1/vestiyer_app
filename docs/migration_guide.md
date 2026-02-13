# Dolap AI - Supabase Şeması Geçiş Kılavuzu

Bu kılavuz, Dolap AI uygulamasının API'larını Supabase veritabanı şemasıyla uyumlu hale getirme sürecini açıklar.

## 1. Temel Değişiklikler

### Tablo Değişiklikleri:
- Ayrı `subscriptions` tablosu yerine, abonelik bilgileri direkt olarak `auth.users` tablosunda tutulacak
- `users` sorgularından `auth.users` sorgularına geçiş yapılacak
- Abonelik durumu kontrolü için yeni tetikleyiciler (triggers) eklenecek

## 2. API Güncellemeleri

### Edge Functions:

#### analyze-and-save-clothing

**Eski Kod:**
```typescript
const { data: subscriptionData, error: subscriptionError } = await supabaseClient
  .from('subscriptions')
  .select('is_premium')
  .eq('user_id', userId)
  .single();

const isPremium = subscriptionData?.is_premium === true;
```

**Yeni Kod:**
```typescript
const { data: subscriptionData, error: subscriptionError } = await supabaseClient
  .from('auth.users')
  .select('is_premium, subscription_end_date')
  .eq('id', userId)
  .single();

const isPremium = subscriptionData?.is_premium === true && 
  (subscriptionData?.subscription_end_date === null || 
   new Date(subscriptionData.subscription_end_date) > new Date());
```

#### manage-premium-status

**Eski Kod:**
```typescript
const { data: roleData, error: roleError } = await supabaseClient
  .from('users')
  .select('role')
  .eq('id', user.id)
  .single();

// Update users table
const { data: userData, error: userError } = await supabaseClient
  .from('users')
  .update({
    is_premium: isPremium,
    // ...
  })
```

**Yeni Kod:**
```typescript
const { data: roleData, error: roleError } = await supabaseClient
  .from('auth.users')
  .select('role')
  .eq('id', user.id)
  .single();

// Update users table
const { data: userData, error: userError } = await supabaseClient
  .from('auth.users')
  .update({
    is_premium: isPremium,
    // ...
  })
```

### Client Servisler:

#### SubscriptionProvider

**Eski Kod:**
```dart
final response = await Supabase.instance.client
    .from('users')
    .select(
        'is_premium, subscription_end_date, subscription_type, free_items_used')
    .eq('id', user.id)
    .single();
```

**Yeni Kod:**
```dart
final response = await Supabase.instance.client
    .from('auth.users')
    .select(
        'is_premium, subscription_end_date, subscription_type, free_items_used')
    .eq('id', user.id)
    .single();
```

#### SupabaseService

**Eski Kod:**
```dart
Future<AuthResponse> signUp(String email, String password) async {
  return await Supabase.instance.client.auth.signUp(
    email: email,
    password: password,
  );
}
```

**Yeni Kod:**
```dart
Future<AuthResponse> signUp(String email, String password) async {
  final response = await Supabase.instance.client.auth.signUp(
    email: email,
    password: password,
  );
  
  // Kullanıcı kaydı başarılı olduysa meta verileri ayarla
  if (response.user != null) {
    await Supabase.instance.client.from('auth.users')
      .update({
        'free_items_used': 0,
        'is_premium': false,
        'subscription_status': 'inactive',
      })
      .eq('id', response.user!.id);
  }
  
  return response;
}
```

## 3. Veritabanı Geçişi

### Yeni Database Migration:

Abonelik durumu ve kıyafet sayısı izleme için tetikleyiciler ekleyerek veri tutarlılığını otomatik olarak sağlayacak yeni bir migration eklenecek:

```sql
-- Create a function to check and update subscription status
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

-- Create a trigger
CREATE TRIGGER update_user_subscription_status
BEFORE UPDATE OR INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION update_subscription_status();

-- Create a function to automatically count clothing items
CREATE OR REPLACE FUNCTION update_free_items_count()
RETURNS TRIGGER AS $$
DECLARE
    items_count INTEGER;
BEGIN
    -- Count user's clothing items
    SELECT COUNT(*) INTO items_count 
    FROM public.clothing_items 
    WHERE user_id = NEW.user_id;
    
    -- Update the free_items_used count in users table
    UPDATE auth.users 
    SET free_items_used = items_count
    WHERE id = NEW.user_id AND is_premium = FALSE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger
CREATE TRIGGER update_free_items_used
AFTER INSERT OR DELETE ON public.clothing_items
FOR EACH ROW
EXECUTE FUNCTION update_free_items_count();
```

## 4. Geçiş Planı

1. **Hazırlık:**
   - Kodun yedeklerini alın
   - Supabase veritabanının yedeğini alın
   - Geliştirme ortamında değişiklikleri test edin

2. **Veritabanı Geçişi:**
   - Yeni migration dosyası oluşturun ve uygulayın
   - Abonelik verileri auth.users tablosunda mevcutsa geçiş için özel bir migration gerekmez

3. **Kod Değişiklikleri:**
   - Edge Functions'ları güncelleyin
   - Flutter uygulamasında `SubscriptionProvider` ve `SupabaseService` sınıflarını güncelleyin
   - Diğer servislerdeki olası kullanım yerlerini tarayın ve güncelleyin

4. **Test:**
   - Premium kullanıcı kontrollerini test edin
   - Kıyafet ekleme/silme işlemlerini test edin
   - Abonelik işlemlerini test edin

5. **Deployment:**
   - Önce Supabase Edge Functions'ları deploy edin
   - Sonra Flutter uygulamasının yeni versiyonunu yayınlayın

## 5. Dikkat Edilmesi Gereken Noktalar

1. **Arayüz Değişiklikleri Yok:** Bu geçiş kullanıcı arayüzünde herhangi bir değişiklik gerektirmez, tamamen backend uyumluluğu ile ilgilidir.

2. **Veritabanı Sorgularında Değişiklik:** `users` yerine `auth.users` kullanıldığından emin olun. Ancak `user_id` sütunu her zaman `id` olarak sorgulanmalıdır.

3. **Premium Kontrolü:** Premium kontrolleri artık abonelik bitiş tarihi ile birlikte yapılmalıdır.

4. **Tetikleyiciler:** Yeni eklenen tetikleyiciler, abonelik durumu ve kıyafet sayısı verilerinin tutarlılığını otomatik olarak sağlar. 