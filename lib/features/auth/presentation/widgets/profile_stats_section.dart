import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/util/localized_number.dart';
import '../../../../core/di/get_it.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/stat_card.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';
import '../../../../core/theme/app_icons.dart';

class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ProductsCubit, ProductsState>(
      bloc: getIt<ProductsCubit>(),
      builder: (context, state) {
        final palette = context.palette;
        final colorScheme = Theme.of(context).colorScheme;
        final locale = Localizations.localeOf(context);
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  value: formatLocalizedInt(locale, state.total),
                  label: l10n.products,
                  icon: AppIcons.products,
                  iconColor: colorScheme.primary,
                  iconBackgroundColor: colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  value: formatLocalizedInt(locale, state.active),
                  label: l10n.active,
                  icon: AppIcons.warranty,
                  iconColor: palette.success,
                  iconBackgroundColor: palette.successContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
