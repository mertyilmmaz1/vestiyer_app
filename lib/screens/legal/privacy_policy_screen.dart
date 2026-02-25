import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../../widgets/vestiyer_page_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VestiyerPageHeader(
              title: l10n.privacyTitle,
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
                      l10n.privacyIntroTitle,
                      l10n.privacyIntroContent,
                    ),
                    _buildSection(
                      l10n.privacyDataCollectedTitle,
                      l10n.privacyDataCollectedContent,
                    ),
                    _buildSection(
                      l10n.privacyDataUsageTitle,
                      l10n.privacyDataUsageContent,
                    ),
                    _buildSection(
                      l10n.privacySecurityTitle,
                      l10n.privacySecurityContent,
                    ),
                    _buildSection(
                      l10n.privacyThirdPartyTitle,
                      l10n.privacyThirdPartyContent,
                    ),
                    _buildSection(
                      l10n.privacyUserRightsTitle,
                      l10n.privacyUserRightsContent,
                    ),
                    _buildSection(
                      l10n.privacyContactTitle,
                      l10n.privacyContactContent,
                    ),
                    _buildSection(
                      l10n.privacyUpdatesTitle,
                      l10n.privacyUpdatesContent,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.termsLastUpdate('${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}'),
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    const url = 'https://vestiyerapp.com/privacy-policy';
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.openInBrowser,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
