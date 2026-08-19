import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constant/app_colors.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../widgets/notification_tile.dart';

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
    context.read<NotificationCubit>().loadNotifications(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
         backgroundColor: AppColors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title:  Text('Notifications',
          style: TextStyle(color: Colors.black, fontSize: 20.sp,
          fontWeight: FontWeight.bold))),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          if (state is NotificationLoading || state is NotificationInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context
                  .read<NotificationCubit>()
                  .loadNotifications(widget.userId),
            );
          }

          final notifications = (state as NotificationLoaded).notifications;

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.white,
            onRefresh: () =>
                context.read<NotificationCubit>().loadNotifications(widget.userId),
            child: ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: ValueKey(notification.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => context
                      .read<NotificationCubit>()
                      .deleteNotification(widget.userId, notification.id),
                  child: NotificationTile(
                    notification: notification,
                    onTap: notification.isRead
                        ? null
                        : () => context
                        .read<NotificationCubit>()
                        .markAsRead(widget.userId, notification.id),
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}