import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';
import '../providers/subscription_provider.dart';
import '../screens/premium_screen.dart';

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
                MaterialPageRoute(
                  builder: (_) => const PremiumScreen(),
                  fullscreenDialog: true,
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
      decoration: BoxDecoration(
        color: AppColors.tertiary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
          left: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
          right: BorderSide(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(left: 20, right: 20, bottom: paddingBottom + 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _buildHandle(),
              const SizedBox(height: 14),
              _buildIcon(),
              const SizedBox(height: 12),
              _buildTitle(),
              const SizedBox(height: 6),
              _buildMessage(),
              const SizedBox(height: 10),
              _buildPriceLine(),
              const SizedBox(height: 12),
              _buildFeatures(features),
              const SizedBox(height: 16),
              _buildCtaButton(context),
              const SizedBox(height: 6),
              _buildRestoreButton(context),
              if (showDismissOption) ...[
                const SizedBox(height: 4),
                _buildDismissButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.diamond_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      type == PaywallType.itemLimit
          ? 'Kıyafet limitine ulaştınız'
          : 'Premium\'a geçin',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildMessage() {
    final defaultMessage = type == PaywallType.itemLimit
        ? 'Premium ile sınırsız kıyafet ve tüm özelliklere erişin.'
        : 'AI kombinleri ve gardırop analizi premium üyeler içindir.';
    final text = customMessage.isNotEmpty ? customMessage : defaultMessage;
    final displayText = text.length > 55 ? '${text.substring(0, 52)}...' : text;
    return Text(
      displayText,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary.withValues(alpha: 0.6),
        height: 1.3,
      ),
    );
  }

  Widget _buildPriceLine() {
    return Text(
      'Aylık ₺59.99 · Yıllık ₺449.99',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildFeatures(List<String> features) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.primary.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    f,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary.withValues(alpha: 0.85),
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
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onUpgrade,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            alignment: Alignment.center,
            child: const Text(
              'Premium\'a geç',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
      child: Text(
        'Satın alımları geri yükle',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textPrimary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildDismissButton() {
    return TextButton(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onDismiss,
      child: Text(
        'Şimdi değil',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
