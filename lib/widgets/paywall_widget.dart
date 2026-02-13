import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../screens/premium_screen.dart';

enum PaywallType {
  itemLimit,
  featureGated,
}

class PaywallWidget extends StatelessWidget {
  final PaywallType type;
  final String customMessage;
  final VoidCallback? onClose;

  const PaywallWidget({
    super.key,
    this.type = PaywallType.itemLimit,
    this.customMessage = '',
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onClose != null)
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.diamond_outlined,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            type == PaywallType.itemLimit
                ? 'Kıyafet Limitine Ulaştınız'
                : 'Premium Özellik',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customMessage.isNotEmpty
                ? customMessage
                : type == PaywallType.itemLimit
                    ? 'Ücretsiz sürümde maksimum ${subscriptionProvider.freeItemLimit} kıyafet ekleyebilirsiniz. Premium abonelikle sınırsız kıyafet ekleyin ve tüm özelliklere erişin.'
                    : 'Bu özellik premium abonelere özeldir. Abone olarak tüm özelliklere sınırsız erişim kazanın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const PremiumScreen(),
                    transitionsBuilder: (_, animation, __, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Premium\'a Yükselt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (type == PaywallType.featureGated)
            TextButton(
              onPressed: onClose,
              child: Text(
                'Şimdi Değil',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Show a dialog with the paywall
  static Future<void> showPaywall(
    BuildContext context, {
    PaywallType type = PaywallType.itemLimit,
    String customMessage = '',
    bool barrierDismissible = true,
  }) async {
    final subscriptionProvider =
        Provider.of<SubscriptionProvider>(context, listen: false);

    // Record last paywall shown timestamp in Firestore
    final user = subscriptionProvider.currentUser;
    if (user != null) {
      await subscriptionProvider.updateLastPaywallShown();
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: PaywallWidget(
            type: type,
            customMessage: customMessage,
            onClose:
                barrierDismissible ? () => Navigator.of(context).pop() : null,
          ),
        ),
      );
    }
  }
}
