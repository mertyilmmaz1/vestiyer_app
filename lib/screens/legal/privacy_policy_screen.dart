import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Gizlilik Politikası',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Giriş',
              'Bu gizlilik politikası, Vestiyer uygulamasının kullanıcı verilerini nasıl topladığını, '
                  'kullandığını ve koruduğunu açıklar. Uygulamamızı kullanarak bu politikayı kabul etmiş olursunuz.',
            ),
            _buildSection(
              'Toplanan Veriler',
              '• Hesap Bilgileri: E-posta adresi, ad ve soyad\n'
                  '• Profil Bilgileri: Profil fotoğrafı, kullanıcı adı\n'
                  '• Dolap İçeriği: Yüklenen ürün fotoğrafları ve açıklamaları\n'
                  '• Kullanım Verileri: Uygulama içi aktiviteler, tercihler\n'
                  '• Cihaz Bilgileri: İşletim sistemi, uygulama versiyonu',
            ),
            _buildSection(
              'Veri Kullanımı',
              'Topladığımız verileri aşağıdaki amaçlar için kullanırız:\n\n'
                  '• Hesabınızı oluşturmak ve yönetmek\n'
                  '• Uygulama özelliklerini sağlamak\n'
                  '• Kullanıcı deneyimini iyileştirmek\n'
                  '• Güvenliği sağlamak\n'
                  '• Yasal yükümlülükleri yerine getirmek',
            ),
            _buildSection(
              'Veri Güvenliği',
              'Verilerinizi korumak için endüstri standardı güvenlik önlemleri kullanıyoruz. '
                  'Veriler şifrelenerek saklanır ve düzenli olarak yedeklenir.',
            ),
            _buildSection(
              'Üçüncü Taraf Hizmetleri',
              'Uygulamamız aşağıdaki üçüncü taraf hizmetlerini kullanabilir:\n\n'
                  '• Google Sign-In\n'
                  '• Facebook Login\n'
                  '• Apple Sign-In\n'
                  '• Firebase Analytics\n'
                  '• Cloud Firestore',
            ),
            _buildSection(
              'Kullanıcı Hakları',
              'Kullanıcılar şu haklara sahiptir:\n\n'
                  '• Verilerine erişim\n'
                  '• Veri düzeltme\n'
                  '• Veri silme\n'
                  '• Veri taşıma\n'
                  '• İtiraz hakkı',
            ),
            _buildSection(
              'İletişim',
              'Gizlilik politikamızla ilgili sorularınız için support@vestiyer.com '
                  'adresinden bizimle iletişime geçebilirsiniz.',
            ),
            _buildSection(
              'Güncellemeler',
              'Bu gizlilik politikası periyodik olarak güncellenebilir. Önemli değişiklikler '
                  'olduğunda kullanıcılarımızı bilgilendireceğiz.',
            ),
            const SizedBox(height: 20),
            Text(
              'Son Güncelleme: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
