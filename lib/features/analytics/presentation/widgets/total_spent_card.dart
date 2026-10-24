import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/di/get_it.dart';
import '../../../../core/service/amount_visibility_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../products/domain/entities/product_entity.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/constant/app_colors.dart';

/// Which purchases the total counts, by purchase date.
enum SpentPeriod { thisMonth, thisYear, allTime }

/// What was spent on the products bought in [period] of [now]'s calendar.
double totalSpentIn(
  List<ProductEntity> products,
  SpentPeriod period,
  DateTime now,
) {
  bool counts(ProductEntity p) => switch (period) {
    SpentPeriod.allTime => true,
    SpentPeriod.thisYear => p.purchaseDate.year == now.year,
    SpentPeriod.thisMonth =>
      p.purchaseDate.year == now.year && p.purchaseDate.month == now.month,
  };
  return products
      .where(counts)
      .fold<double>(0, (sum, p) => sum + (p.price ?? 0));
}

/// Brand-gradient hero card with what was spent this month, this year or
/// in all. The eye button hides the amount (remembered on this device).
class TotalSpentCard extends StatefulWidget {
  const TotalSpentCard({super.key, required this.state, required this.l10n});

  final ProductsState state;
  final AppLocalizations l10n;

  @override
  State<TotalSpentCard> createState() => _TotalSpentCardState();
}

class _TotalSpentCardState extends State<TotalSpentCard> {
  SpentPeriod _period = SpentPeriod.allTime;

  ProductsState get state => widget.state;
  AppLocalizations get l10n => widget.l10n;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.brandGradientColors,
  );

  @override
  Widget build(BuildContext context) {
    final isInitialLoading = state.isLoading && state.products.isEmpty;
    final appLocale = Localizations.localeOf(context);
    // Arabic gets Arabic-Indic digits, like the rest of the app.
    final locale = appLocale.languageCode == 'ar'
        ? 'ar_EG'
        : appLocale.toLanguageTag();
    final amount = NumberFormat.decimalPattern(
      locale,
    ).format(totalSpentIn(state.products, _period, DateTime.now()).round());
    final visibility = getIt<AmountVisibilityController>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x404A5CFA),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Soft decorative circles.
            PositionedDirectional(
              top: -40,
              end: -30,
              child: _Circle(size: 140, opacity: 0.10),
            ),
            PositionedDirectional(
              bottom: -50,
              end: 60,
              child: _Circle(size: 110, opacity: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          AppIcons.wallet,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.totalSpant,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: visibility,
                        builder: (context, hidden, _) => IconButton(
                          onPressed: visibility.toggle,
                          tooltip: hidden
                              ? l10n.showTotalSpent
                              : l10n.hideTotalSpent,
                          icon: Icon(
                            hidden ? AppIcons.hide : AppIcons.show,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Skeletonizer(
                    enabled: isInitialLoading,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: visibility,
                      builder: (context, hidden, _) => Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          // Hidden = the real number, blurred (fades in/out).
                          // Tapping it toggles too, not just the eye button.
                          Semantics(
                            label: hidden ? l10n.totalSpentHidden : null,
                            excludeSemantics: hidden,
                            child: GestureDetector(
                              onTap: isInitialLoading
                                  ? null
                                  : visibility.toggle,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  end: hidden && !isInitialLoading ? 12 : 0,
                                ),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                                builder: (context, sigma, child) =>
                                    ImageFiltered(
                                      enabled: sigma > 0.1,
                                      imageFilter: ImageFilter.blur(
                                        sigmaX: sigma,
                                        sigmaY: sigma,
                                        tileMode: TileMode.decal,
                                      ),
                                      child: child,
                                    ),
                                child: Text(
                                  isInitialLoading ? '1,234' : amount,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Text(
                            '  EGP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PeriodSwitch(
                    selected: _period,
                    labels: {
                      SpentPeriod.thisMonth: l10n.periodThisMonth,
                      SpentPeriod.thisYear: l10n.periodThisYear,
                      SpentPeriod.allTime: l10n.periodAllTime,
                    },
                    onChanged: (p) => setState(() => _period = p),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: opacity),
      shape: BoxShape.circle,
    ),
  );
}

/// Three pills on the gradient: white with brand text when picked,
/// translucent otherwise.
class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  final SpentPeriod selected;
  final Map<SpentPeriod, String> labels;
  final ValueChanged<SpentPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final MapEntry(key: period, value: label) in labels.entries)
            Expanded(
              child: Semantics(
                button: true,
                selected: period == selected,
                child: GestureDetector(
                  onTap: () => onChanged(period),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: period == selected
                          ? Colors.white
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: period == selected
                            ? AppColors.primary
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
