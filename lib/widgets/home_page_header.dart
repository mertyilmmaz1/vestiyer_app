import 'package:flutter/material.dart';
import 'package:vestiyer_nodejs/core/product/theme/app_colors.dart';

/// Referans tasarım: profil avatar + "Hoşgeldin [firstName]! 👋" + alt bilgi + bildirim.
class HomePageHeader extends StatelessWidget {
  const HomePageHeader({
    super.key,
    required this.firstName,
    required this.subtitle,
    this.avatarUrl,
    this.onNotificationTap,
    this.onProfileTap,
  });

  final String? firstName;
  final String subtitle;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    final displayName = (firstName ?? '').trim().isNotEmpty ? firstName! : 'Kullanıcı';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.tertiary,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(Icons.person_outline, color: AppColors.textPrimary.withValues(alpha: 0.6), size: 32)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Hoşgeldin ',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      TextSpan(
                        text: '$displayName! ',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const TextSpan(
                        text: '👋',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
              size: 26,
            ),
            onPressed: onNotificationTap ?? () {},
            tooltip: 'Bildirimler',
          ),
        ],
      ),
    );
  }
}
