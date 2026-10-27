/// Which reminder an in-app notification is. Stored by name, so names must
/// not change.
enum NotificationKind {
  warrantyExpiring,
  warrantyExpired,
  subscriptionRenewal,
  subscriptionRenewed,
  installmentDueSoon,
  installmentDueToday,
  paperExpiring,
  paperExpired,
}

/// Which reminder a notification is and the facts its text is built from,
/// so the list can show it in the app's current language (see
/// notificationTitle and notificationBody). Saved with the notification; its
/// stored title and subtitle stay as the fallback.
///
/// [args] by kind:
/// - warranty: `product`, `days`
/// - subscription: `name`, `days`, `price`, `currency`
/// - installment: `name`, `days`, `amount`, `currency`
/// - paper: `paperKind`, `title` (may be null), `days`
class NotificationMessage {
  const NotificationMessage(this.kind, this.args);

  final NotificationKind kind;
  final Map<String, Object?> args;

  Map<String, Object?> toJson() => {'kind': kind.name, 'args': args};

  /// Null for a row without one (made before this existed) or a kind this
  /// version doesn't know.
  static NotificationMessage? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = NotificationKind.values.asNameMap()[json['kind']];
    final args = json['args'];
    if (kind == null || args is! Map) return null;
    return NotificationMessage(kind, Map<String, Object?>.from(args));
  }
}
