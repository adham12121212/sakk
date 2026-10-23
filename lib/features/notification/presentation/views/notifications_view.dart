import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_refresh_indicator.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/notification_enitiy.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../widgets/notification_tile.dart';
import '../../../../core/theme/app_icons.dart';

class NotificationsView extends StatefulWidget {
  final String userId;
  const NotificationsView({super.key, required this.userId});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  @override
  void initState() {
    super.initState();
    context.read<NotificationCubit>()
      ..watch(widget.userId)
      ..refresh();
  }

  List<NotificationEntity> _placeholderNotifications() {
    final now = DateTime.now();
    return List.generate(
      5,
      (i) => NotificationEntity(
        id: 'placeholder-$i',
        userId: widget.userId,
        title: 'Notification title',
        subtitle: 'Notification subtitle text goes here',
        type: NotificationType.info,
        createdAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.back),
          tooltip: l10n.back,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.notifications),
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            final placeholders = _placeholderNotifications();
            return Skeletonizer(
              enabled: true,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: placeholders.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    NotificationTile(notification: placeholders[index]),
              ),
            );
          }
          if (state is NotificationError) {
            return AppErrorView(
              message: state.message,
              onRetry: () => context
                  .read<NotificationCubit>()
                  .loadNotifications(widget.userId),
              fillRemaining: true,
            );
          }
          final notifications = (state as NotificationLoaded).notifications;
          final cubit = context.read<NotificationCubit>();
          return AppRefreshIndicator(
            onRefresh: () => cubit.loadNotifications(widget.userId),
            child: notifications.isEmpty
                ? AppEmptyView(
                    icon: AppIcons.notifications,
                    title: l10n.nonotificationsyet,
                    fillRemaining: true,
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Dismissible(
                        key: ValueKey(notification.id),
                        direction: DismissDirection.endToStart,
                        // Rounded red panel on the trailing side (mirrors in RTL).
                        background: Container(
                          alignment: AlignmentDirectional.centerEnd,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: context.palette.danger,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            AppIcons.delete,
                            color: Colors.white,
                          ),
                        ),
                        onDismissed: (_) => cubit.deleteNotification(
                          widget.userId,
                          notification.id,
                        ),
                        child: NotificationTile(
                          notification: notification,
                          onTap: notification.isRead
                              ? null
                              : () => cubit.markAsRead(
                                  widget.userId,
                                  notification.id,
                                ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
