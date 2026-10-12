import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constant/app_colors.dart';
import '../../core/route/app_router.dart';
import '../../l10n/app_localizations.dart';
import '../../core/theme/app_icons.dart';


class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isHome = navigationShell.currentIndex == 0;
    // Android back on any other tab goes to Home; only Home leaves the app.
    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: _BottomBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}

/// White bar with a soft top shadow: the active tab's icon sits in a tinted
/// pill, and Scan (the app's main action) is a raised round button.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: isDark ? Border(top: BorderSide(color: colorScheme.outline)) : null,
        boxShadow: isDark
            ? null
            : const [BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _NavItem(
                icon: AppIcons.home,
                activeIcon: AppIcons.homeFilled,
                label: l10n.home,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: AppIcons.productsTab,
                activeIcon: AppIcons.productsTabFilled,
                label: l10n.products,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _ScanItem(
                label: l10n.scan,
                onTap: () => context.push(AppRoutes.scan),
              ),
              _NavItem(
                icon: AppIcons.analytics,
                activeIcon: AppIcons.analyticsFilled,
                label: l10n.analytics,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: AppIcons.ai,
                activeIcon: AppIcons.aiFilled,
                label: l10n.ai,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isActive ? AppColors.primary : colorScheme.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 32,
          child: Column(
            // Bottom-aligned so every label shares one baseline (the Scan
            // circle is taller and rises above the others).
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(isActive ? activeIcon : icon, color: color, size: 22),
              ),
              const SizedBox(height: 4),
              _Label(
                label,
                TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanItem extends StatelessWidget {
  const _ScanItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 34,
          child: Column(
            // Bottom-aligned so every label shares one baseline (the Scan
            // circle is taller and rises above the others).
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppColors.brandGradientColors,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(AppIcons.scan, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 4),
              _Label(
                label,
                TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// One-line tab label that shrinks to fit instead of being cut off
/// (e.g. Arabic «الذكاء الاصطناعي»).
class _Label extends StatelessWidget {
  const _Label(this.text, this.style);

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, style: style.copyWith(height: 1.2)),
      ),
    );
  }
}
