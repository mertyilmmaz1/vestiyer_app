import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/navigation/editorial_page_route.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../providers/subscription_provider.dart';
import '../screens/premium_screen.dart';
import 'bouncing_widget.dart';

enum PaywallType {
  itemLimit,
  featureGated,
}

/// Paywall yalnızca [showPaywall] ile bottom sheet olarak gösterilir.
class PaywallWidget extends StatelessWidget {
  const PaywallWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// Paywall'ı bottom sheet olarak açar. Tüm paywall gösterimleri bu metod ile yapılmalıdır.
  /// [itemLimit]: barrier dışına tıklanarak kapatılamaz.
  /// [featureGated]: barrier dismissible, "Şimdi değil" gösterilir.
  static Future<void> showPaywall(
    BuildContext context, {
    PaywallType type = PaywallType.itemLimit,
    String customMessage = '',
  }) async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    final user = subscriptionProvider.currentUser;
    if (user != null) {
      await subscriptionProvider.updateLastPaywallShown();
    }

    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final barrierDismissible = type == PaywallType.featureGated;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: barrierDismissible,
      enableDrag: barrierDismissible,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.5;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: _PaywallBottomSheetContent(
            type: type,
            customMessage: customMessage,
            subscriptionProvider: subscriptionProvider,
            onUpgrade: () async {
              Navigator.pop(sheetContext);
              if (!context.mounted) return;
              await navigator.push<void>(
                EditorialPageRoute(
                  page: const PremiumScreen(),
                ),
              );
              if (context.mounted) {
                await subscriptionProvider.refreshSubscriptionStatus();
              }
            },
            onDismiss: () => Navigator.pop(sheetContext),
            showDismissOption: barrierDismissible,
          ),
        );
      },
    );
  }
}

class _PaywallBottomSheetContent extends StatelessWidget {
  final PaywallType type;
  final String customMessage;
  final SubscriptionProvider subscriptionProvider;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;
  final bool showDismissOption;

  const _PaywallBottomSheetContent({
    required this.type,
    required this.customMessage,
    required this.subscriptionProvider,
    required this.onUpgrade,
    required this.onDismiss,
    required this.showDismissOption,
  });

  @override
  Widget build(BuildContext context) {
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    final features = subscriptionProvider.getPremiumFeatures().take(2).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.textPrimary,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
              left: 24, right: 24, bottom: paddingBottom + 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIcon(),
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildMessage(),
              const SizedBox(height: 24),
              _buildPriceLine(),
              const SizedBox(height: 24),
              _buildFeatures(features),
              const SizedBox(height: 32),
              _buildCtaButton(context),
              const SizedBox(height: 16),
              _buildRestoreButton(context),
              if (showDismissOption) ...[
                const SizedBox(height: 8),
                _buildDismissButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return const Icon(
      Icons.diamond_outlined,
      color: AppColors.textPrimary,
      size: 48,
    );
  }

  Widget _buildTitle() {
    return Text(
      type == PaywallType.itemLimit ? 'DOLABINIZ DOLDU' : 'PREMIUM ÖZELLİK',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 2.0,
      ),
    );
  }

  Widget _buildMessage() {
    final defaultMessage = type == PaywallType.itemLimit
        ? 'Sınırsız kıyafet eklemek ve dolabınızı özgürce yönetmek için Premium\'a geçin.'
        : 'Yapay zeka analizlerine ve özel stil asistanına erişmek için Premium\'a geçin.';
    final text = customMessage.isNotEmpty ? customMessage : defaultMessage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.5,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildPriceLine() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.softBackground,
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: const Text(
        'AYLIK ₺59.99  ·  YILLIK ₺449.99',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFeatures(List<String> features) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      f,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCtaButton(BuildContext context) {
    return BouncingWidget(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onUpgrade,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.textPrimary,
            foregroundColor: AppColors.background,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: const Text(
            'PREMIUM\'A GEÇ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: () async {
        await subscriptionProvider.restorePurchases();
        if (!context.mounted) return;
        if (subscriptionProvider.isPremium) {
          Navigator.pop(context);
        }
      },
      child: const Text(
        'Satın alımları geri yükle',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Widget _buildDismissButton() {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onDismiss,
      child: const Text(
        'ŞİMDİ DEĞİL',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
