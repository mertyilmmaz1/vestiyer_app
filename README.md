# 📱 Vestiyer - Node.js Backend Integration

Bu proje, Vestiyer mobil uygulamasının Node.js + MongoDB backend entegrasyonu sürümüdür. Daha önce Supabase ile çalışan uygulama artık özel Node.js backend'i kullanmaktadır.

## 🚀 Özellikler

- **JWT Authentication**: Node.js backend ile güvenli kullanıcı kimlik doğrulama
- **AI Kıyafet Analizi**: OpenAI API ile kıyafet analizi ve kategorize etme
- **Kombination Önerileri**: AI destekli kombin önerileri
- **Mevsim Filtreleme**: Kıyafetleri mevsime göre filtreleme
- **Premium Abonelik**: Ücretsiz limit ve premium özellikler
- **Modern UI**: Flutter ile responsive ve kullanıcı dostu arayüz

## 🏗️ Teknoloji Stack

### Frontend (Flutter)
- **Flutter**: 3.2.3+
- **State Management**: Provider pattern
- **HTTP Client**: dart:http
- **Image Processing**: image package
- **Local Storage**: shared_preferences

### Backend (Node.js)
- **Node.js**: Express.js framework
- **Database**: MongoDB
- **Authentication**: JWT tokens
- **AI Integration**: OpenAI GPT-4o-mini
- **Image Processing**: Base64 image upload

## 📦 Kurulum

### 1. Flutter Uygulaması

```bash
# Dependencies'leri yükle
flutter pub get

# iOS için (macOS'ta)
cd ios && pod install && cd ..

# Uygulamayı çalıştır
flutter run
```

### 2. Backend Gereksinimler

Backend sunucusunun çalışır durumda olması gerekir. Backend proje klasöründe:

```bash
# Backend dependencies'leri yükle
npm install

# Environment variables'ları ayarla
cp .env.example .env

# MongoDB ve OpenAI API key'lerini .env dosyasına ekle
MONGODB_URI=mongodb://localhost:27017/vestiyer
OPENAI_API_KEY=your_openai_api_key

# Backend'i başlat
npm start
```

Backend varsayılan olarak `http://localhost:3000` adresinde çalışır.

### 3. API Configuration

Flutter uygulamasında API base URL'ini yapılandırın:

```dart
// lib/services/vestiyer_api_service.dart
static const String baseUrl = 'http://localhost:3000'; // Development
// static const String baseUrl = 'https://your-api-domain.com'; // Production
```

## 🔧 Yapılandırma

### API Endpoints

Uygulama aşağıdaki ana endpoint'leri kullanır:

- **Authentication**: `/api/auth/*`
  - `POST /api/auth/register` - Kullanıcı kaydı
  - `POST /api/auth/login` - Kullanıcı girişi
  - `GET /api/auth/profile` - Kullanıcı profili

- **Clothing**: `/api/clothing/*`
  - `POST /api/clothing/analyze-and-add` - Kıyafet analizi ve ekleme
  - `GET /api/clothing/{userId}` - Kullanıcı kıyafetleri
  - `GET /api/clothing/{userId}/statistics` - İstatistikler

- **Combinations**: `/api/combinations/*`
  - `POST /api/combinations/generate` - AI kombin önerileri
  - `GET /api/combinations/user/{userId}` - Kullanıcı kombinleri

### Environment Variables

Flutter uygulaması için özel environment variables gerekmez. Tüm konfigürasyon code içerisinde yapılır.

Backend için gerekli environment variables:
- `MONGODB_URI`: MongoDB bağlantı string'i
- `OPENAI_API_KEY`: OpenAI API anahtarı
- `JWT_SECRET`: JWT token'ları için secret key

## 📱 Uygulama Yapısı

```
lib/
├── main.dart                 # Uygulama giriş noktası
├── models/                   # Data model'leri
│   ├── user.dart            # Kullanıcı modeli
│   ├── clothing.dart        # Kıyafet modeli
│   ├── combination.dart     # Kombination modeli
│   └── api_response.dart    # API response model'leri
├── services/                # Servis katmanı
│   └── vestiyer_api_service.dart # Ana API servisi
├── providers/               # State management
│   ├── wardrobe_provider.dart    # Kıyafet state'i
│   └── subscription_provider.dart # Abonelik state'i
├── screens/                 # UI ekranları
│   ├── login_screen.dart    # Giriş ekranı
│   ├── home_screen.dart     # Ana ekran
│   ├── wardrobe_screen.dart # Dolap ekranı
│   └── ...
└── widgets/                 # Tekrar kullanılabilir widget'lar
```

## 🔄 Supabase'den Migration

Bu proje Supabase tabanlı versiyondan türetilmiştir. Ana değişiklikler:

1. **Authentication**: Supabase Auth → JWT Authentication
2. **Database**: Supabase DB → MongoDB
3. **Storage**: Supabase Storage → Base64 image upload
4. **Edge Functions**: Supabase Functions → Express.js endpoints
5. **State Management**: Supabase listeners → Provider pattern

### Migration Checklist

- [x] Authentication sistemi güncellendi
- [x] API servis katmanı oluşturuldu
- [x] Data model'leri güncellendi
- [x] Provider'lar uyarlandı
- [x] Login screen güncellendi
- [ ] Diğer screen'ler güncelleniyor
- [ ] Testing ve deployment

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter test integration_test/
```

### API Testing

Backend API'larını test etmek için API endpoint'leri dokümantasyonuna bakın.

## 🚦 Development vs Production

### Development

```dart
// Development için local backend
static const String baseUrl = 'http://localhost:3000';
```

### Production

```dart
// Production için deployed backend
static const String baseUrl = 'https://api.vestiyer.com';
```

## 🐛 Troubleshooting

### Common Issues

1. **Connection Refused**: Backend sunucusunun çalıştığından emin olun
2. **Authentication Errors**: JWT token'ların doğru şekilde kaydedildiğini kontrol edin
3. **Image Upload Issues**: Base64 encoding ve image compression ayarlarını kontrol edin

### Logs

```bash
# Flutter logs
flutter logs

# Backend logs
npm logs
```

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

Sorularınız için:
- Issue açın GitHub'da
- Dokümantasyonu kontrol edin
- Backend API dokümantasyonuna bakın

---

**Not**: Bu proje Node.js backend entegrasyonu sürümüdür. Supabase versiyonu için orijinal `dolap_ai` klasörüne bakın.
