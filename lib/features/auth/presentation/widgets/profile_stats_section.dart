import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/widgets/stat_card.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../../products/presentation/cubit/product_state.dart';



class ProfileStatsSection extends StatelessWidget {
  const ProfileStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ProductsCubit, ProductsState>(
      bloc: getIt<ProductsCubit>(),
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${state.total}',
                label: l10n.products,
                icon: Icons.inventory_2_outlined,
                iconColor: AppColors.primary,
                iconBackgroundColor: AppColors.primary.withOpacity(0.1),
              ),
            ),
            SizedBox(width: AppSizes.s12),
            Expanded(
              child: StatCard(
                value: '${state.active}',
                label: l10n.active,
                icon: Icons.shield_outlined,
                iconColor: AppColors.success,
                iconBackgroundColor: AppColors.success.withOpacity(0.1),
              ),
            ),
          ],
        );
      },
    );
  }
}