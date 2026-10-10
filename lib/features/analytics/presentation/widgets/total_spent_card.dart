import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../../core/theme/app_icons.dart';

/// Brand-gradient hero card with the total spent across all products.
class TotalSpentCard extends StatelessWidget {
  const TotalSpentCard({super.key, required this.state, required this.l10n});

  final ProductsState state;
  final AppLocalizations l10n;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3D7BFF), Color(0xFF5B3DF5)],
  );

  @override
  Widget build(BuildContext context) {
    final isInitialLoading = state.isLoading && state.products.isEmpty;
    final appLocale = Localizations.localeOf(context);
    // Arabic gets Arabic-Indic digits, like the rest of the app.
    final locale = appLocale.languageCode == 'ar' ? 'ar_EG' : appLocale.toLanguageTag();
    final amount = NumberFormat.decimalPattern(locale).format(state.totalPrice.round());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x404A5CFA), blurRadius: 24, offset: Offset(0, 10)),
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
                        child: const Icon(AppIcons.wallet, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.totalSpant,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Skeletonizer(
                    enabled: isInitialLoading,
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: isInitialLoading ? '1,234' : amount,
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                        ),
                        const TextSpan(
                          text: '  EGP',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ]),
                      style: const TextStyle(color: Colors.white),
                    ),
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
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: opacity), shape: BoxShape.circle),
      );
}
