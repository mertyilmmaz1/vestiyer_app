import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../../widgets/vestiyer_page_header.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const VestiyerPageHeader(
              title: 'Kullanım Şartları',
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
              'Kabul Edilen Şartlar',
              'Bu kullanım şartları, Vestiyer uygulamasını kullanımınızı düzenler. '
                  'Uygulamayı kullanarak bu şartları kabul etmiş olursunuz.',
            ),
            _buildSection(
              'Hesap Oluşturma',
              '• 18 yaşından büyük olmalısınız\n'
                  '• Doğru ve güncel bilgiler sağlamalısınız\n'
                  '• Hesap güvenliğinizden siz sorumlusunuz\n'
                  '• Hesabınızı başkalarıyla paylaşmamalısınız',
            ),
            _buildSection(
              'Kullanıcı Sorumlulukları',
              'Aşağıdaki içeriklerin paylaşılması yasaktır:\n\n'
                  '• Yasa dışı ürünler\n'
                  '• Sahte ürünler\n'
                  '• Uygunsuz içerik\n'
                  '• Spam veya yanıltıcı içerik\n'
                  '• Başkalarının haklarını ihlal eden içerik',
            ),
            _buildSection(
              'Ürün Listeleme Kuralları',
              '• Ürünler doğru kategoride listelenmelidir\n'
                  '• Fotoğraflar ürünü net göstermelidir\n'
                  '• Fiyatlar makul ve gerçekçi olmalıdır\n'
                  '• Ürün açıklamaları doğru ve detaylı olmalıdır',
            ),
            _buildSection(
              'Alım-Satım İşlemleri',
              '• Tüm işlemler uygulama üzerinden yapılmalıdır\n'
                  '• Uygulama dışı işlemlerden Vestiyer sorumlu değildir\n'
                  '• Ödeme ve kargo süreçleri belirtilen şekilde yürütülmelidir\n'
                  '• İade süreçleri belirlenen politikalara uygun olmalıdır',
            ),
            _buildSection(
              'Fikri Mülkiyet',
              'Vestiyer\'in tüm hakları saklıdır. Uygulama içeriği, logo ve tasarımlar '
                  'izinsiz kullanılamaz ve kopyalanamaz.',
            ),
            _buildSection(
              'Hesap Askıya Alma',
              'Aşağıdaki durumlarda hesabınız askıya alınabilir:\n\n'
                  '• Kullanım şartlarının ihlali\n'
                  '• Sahte ürün satışı\n'
                  '• Uygunsuz davranış\n'
                  '• Dolandırıcılık',
            ),
            _buildSection(
              'Sorumluluk Reddi',
              'Vestiyer, kullanıcılar arasındaki işlemlerden doğan sorunlardan '
                  'doğrudan sorumlu değildir. Ancak sorunların çözümü için destek sağlar.',
            ),
            _buildSection(
              'Değişiklikler',
              'Bu kullanım şartları periyodik olarak güncellenebilir. Değişiklikler '
                  'hakkında kullanıcılar bilgilendirilecektir.',
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
          borderRadius: BorderRadius.zero,
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
