import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constant/app_colors.dart';
import '../../../../core/di/get_it.dart';
import '../../../../core/route/app_router.dart';
import '../../../../core/util/app_sizes.dart';
import '../../../../core/util/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/usecase/get_user_usecase.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_logout_button.dart';
import '../widgets/profile_settings_card.dart';
import '../widgets/profile_stats_section.dart';
import '../widgets/section_label.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {

    final user = getIt<GetUserUseCase>()();
    final displayName = (user?.name.trim().isNotEmpty ?? false)
        ? user!.name.trim()
        : (user?.email.split('@').first ?? 'there');
    final displayEmail = user?.email ?? '';

    return BlocListener<AuthCubit, AuthState>(

      listenWhen: (previous, current) =>
      previous is AuthLoading && current is AuthInitial,
      listener: (context, state) {
        context.go(AppRoutes.signin);
      },
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) => current is AuthError,
        listener: (context, state) {
          final message = (state as AuthError).message;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(message),
              backgroundColor: AppColors.error,
            ));
        },
        child: Scaffold(
          backgroundColor: AppColors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(
                  displayName: displayName,
                  displayEmail: displayEmail,
                  avatarUrl: user?.avatarUrl,
                  onBack: () => Navigator.pop(context),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.s20, AppSizes.s20, AppSizes.s20, AppSizes.s8,
                  ),
                  child: Column(
                    children: [
                      const ProfileStatsSection(),
                      AppSpacing.h32,
                      SectionLabel(AppLocalizations.of(context)!.preferences),
                      AppSpacing.h12,
                      const ProfileSettingsCard(),
                      AppSpacing.h24,
                      const ProfileLogoutButton(),
                      AppSpacing.h24,
                    ],
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