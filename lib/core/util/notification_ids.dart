/// Ids for scheduled local notifications.
///
/// flutter_local_notifications needs a 32-bit int id. Each reminder's id is a
/// stable hash of the thing it's about (product or subscription id) with the
/// last digit as a "slot" saying which reminder it is:
///   0, 1, 2  warranty: expiring soon, expired, return window closing
///   5        subscription: renewing soon
/// Each service only touches its own slots, so syncing one never cancels the
/// other's reminders.
///
/// FNV-1a rather than String.hashCode, which Dart doesn't guarantee across
/// releases, so an app update can still find and cancel what an older
/// version scheduled. Changing this breaks that: old reminders become
/// unreachable.
int reminderNotificationId(String entityId, int slot) {
  assert(slot >= 0 && slot <= 9);
  var hash = 0x811c9dc5;
  for (final unit in entityId.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return (hash & 0x7FFFFFFF) ~/ 10 * 10 + slot;
}

/// The slot of a reminder id (see [reminderNotificationId]).
int reminderSlot(int id) => id % 10;

const warrantyReminderSlots = {0, 1, 2};
const subscriptionRenewalSlot = 5;
