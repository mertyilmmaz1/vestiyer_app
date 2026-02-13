import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../../widgets/vestiyer_page_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VestiyerPageHeader(
              title: 'Gizlilik Politikası',
              showBackButton: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                color: AppColors.textPrimary.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.tertiary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
