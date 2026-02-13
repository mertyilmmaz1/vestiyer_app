# Dolap AI - Proje Dokümentasyonu

Dolap AI, yapay zeka destekli bir kıyafet asistanı uygulamasıdır. Bu dokümentasyon, projenin teknik yapısını, bileşenlerini ve geliştiriciler için önemli bilgileri içerir.

## Proje Yapısı

### Backend
Dolap AI projesi, Supabase platformunu backend olarak kullanmaktadır:

- **Veritabanı**: PostgreSQL tabanlı Supabase veritabanı
- **Authentication**: Supabase Auth sistemi (JWT tabanlı)
- **Edge Functions**: Sunucu taraflı işlemler için Supabase Edge Functions
- **Storage**: Kıyafet görselleri için Supabase Storage

### Frontend
- **Framework**: Flutter
- **State Management**: Provider pattern
- **UI Tasarım**: Custom UI bileşenleri

## Veritabanı Şeması ve API Yapısı

Projenin veritabanı şeması ve API yapısı ile ilgili ayrıntılı bilgiler için [Supabase Şema Dokümanı](./supabase_schema.md) dosyasını inceleyebilirsiniz.

## API Entegrasyonları

### OpenAI Entegrasyonu
Uygulama kıyafet analizi ve kombin önerileri için GPT-4 Vision API'sini kullanır:

- Kıyafet analizi: Yüklenen görseli analiz ederek renk, stil, materyal gibi özellikleri belirler
- Kombin önerileri: Mevcut kıyafetlere göre stil önerileri sunar

## Geliştirme Kılavuzu

### Yerel Ortam Kurulumu

1. Supabase CLI kurulumu:
```bash
npm install -g supabase
```

2. Yerel Supabase kurulumu:
```bash
cd vestiyer
supabase init
supabase start
```

3. Flutter paketlerinin yüklenmesi:
```bash
flutter pub get
```

### Edge Functions Geliştirme

Edge Functions şu dizinde bulunur: `supabase/functions/`

Bir Edge Function'ı lokal olarak çalıştırmak:
```bash
supabase functions serve analyze-and-save-clothing --no-verify-jwt
```

Bir Edge Function'ı deploy etmek:
```bash
supabase functions deploy analyze-and-save-clothing
```

### API İsteklerini Test Etme

Supabase yerel geliştirmede, API isteklerini aşağıdaki base URL ile test edebilirsiniz:
```
http://localhost:54321/functions/v1/<function-name>
```

Örnek bir curl komutu:
```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/analyze-and-save-clothing' \
  --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
  --header 'Content-Type: application/json' \
  --data '{
    "base64Image": "...",
    "userId": "user-uuid",
    "imageUrl": "https://example.com/image.jpg"
  }'
```

## Dikkat Edilmesi Gereken Değişiklikler

### auth.users Kullanımı
Supabase sorgularında auth.users tablosuna doğrudan erişim sağlanmalıdır:

```dart
// Doğru kullanım
final response = await supabase
    .from('auth.users')
    .select('is_premium, subscription_end_date')
    .eq('id', userId)
    .single();

// Yanlış kullanım (çalışmayacaktır)
final response = await supabase
    .from('users')  // veya 'subscriptions'
    .select('is_premium')
    .eq('user_id', userId)
    .single();
```

### Premium Kontrolleri

Premium kontrolleri hem `is_premium` durumunu hem de abonelik bitiş tarihini kontrol etmelidir:

```dart
final isPremium = userData?.is_premium === true && 
  (userData?.subscription_end_date === null || 
   new Date(userData.subscription_end_date) > new Date());
```

## İletişim

Proje ile ilgili sorularınız veya katkılarınız için:
- GitHub Issues: [Dolap AI Issues](https://github.com/your-org/vestiyer/issues) 