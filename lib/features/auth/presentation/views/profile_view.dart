import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null || !context.mounted) return;
    context.read<AuthCubit>().updateAvatar(File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    // Cached session user — used as the initial/fallback source, since this
    // AuthCubit instance starts at AuthInitial each time this screen opens.
    final fallbackUser = getIt<GetUserUseCase>()();

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
              body: SingleChildScrollView(
            child: BlocBuilder<AuthCubit, AuthState>(
              buildWhen: (previous, current) =>
              current is AuthAvatarUpdated ||
                  current is AuthAvatarUpdating ||
                  previous is AuthAvatarUpdating,
              builder: (context, state) {
                final updatedUser = state is AuthAvatarUpdated ? state.user : null;
                debugPrint('[ProfileView] updatedUser.avatarUrl = ${updatedUser?.avatarUrl}');
                final isUploadingAvatar = state is AuthAvatarUpdating;
                final l10n = AppLocalizations.of(context)!;

                final effectiveName = updatedUser != null
                    ? (updatedUser.name.trim().isNotEmpty
                    ? updatedUser.name.trim()
                    : updatedUser.email.split('@').first)
                    : ((fallbackUser?.name.trim().isNotEmpty ?? false)
                    ? fallbackUser!.name.trim()
                    : (fallbackUser?.email.split('@').first ?? l10n.guestFallbackName));
                final effectiveEmail = updatedUser?.email ?? fallbackUser?.email ?? '';
                final effectiveAvatarUrl = updatedUser?.avatarUrl ?? fallbackUser?.avatarUrl;

                return Column(
                  children: [
                    ProfileHeader(
                      displayName: effectiveName,
                      displayEmail: effectiveEmail,
                      avatarUrl: effectiveAvatarUrl,
                      onBack: () => Navigator.pop(context),
                      onPickAvatar: () => _pickAndUploadAvatar(context),
                      isUploadingAvatar: isUploadingAvatar,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSizes.s20, AppSizes.s20, AppSizes.s20, AppSizes.s8,
                      ),
                      child: Column(
                        children: [
                          const ProfileStatsSection(),
                          AppSpacing.h32,
                          SectionLabel(l10n.preferences,
                          ),
                          AppSpacing.h12,
                          const ProfileSettingsCard(),
                          AppSpacing.h24,
                          const ProfileLogoutButton(),
                          AppSpacing.h24,
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}