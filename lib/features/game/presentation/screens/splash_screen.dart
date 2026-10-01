import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/brand.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/widgets/common.dart';

/// The logo, then ظامتنا — DHAMETNA — Mauritanian Traditional Game.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.go(AppRoutes.home);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(fade),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLogo(size: 128),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  Brand.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: AppTypography.logo.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  Brand.nameLatin.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    letterSpacing: 10,
                    fontFamily: AppTypography.displayFamily,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.appTagline,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
