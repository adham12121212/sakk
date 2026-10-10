import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../home/presentation/widgets/circle_icon_button.dart';
import '../../../../l10n/app_localizations.dart';

class SignupHeader extends StatelessWidget {
  const SignupHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back,
            semanticLabel: l10n.back,
            onTap: () => context.pop(),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.createAccount, style: Theme.of(context).textTheme.headlineSmall),
                Text(
                  l10n.joinSakkToday,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}