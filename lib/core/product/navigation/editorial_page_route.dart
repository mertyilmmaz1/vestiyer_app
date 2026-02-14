import 'package:flutter/material.dart';

/// Editorial geçiş - fade, 450ms, easeInOut.
/// Rehber: Slide değil fade, animasyon yavaş.
class EditorialPageRoute<T> extends PageRouteBuilder<T> {
  EditorialPageRoute({
    required Widget page,
    RouteSettings? settings,
  }) : super(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 450),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
        );
}
