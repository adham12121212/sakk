/// Ids for scheduled local notifications.
///
/// flutter_local_notifications needs a 32-bit int id. Each reminder's id is a
/// stable hash of the thing it's about (product, subscription or installment
/// payment id) with the last digit as a "slot" saying which reminder it is:
///   0, 1, 2     warranty: expiring soon, expired, return window closing
///   3, 4        installment: due in 3 days, due today
///   5, 6, 7, 8  subscription: renews in 3 days, renews tomorrow, renewed
///               (next renewal), renewed (the one that just passed)
///   9           Sakk Pro's "N days before", for subscriptions and
///               installments alike; told apart by the payload (an
///               installment's starts with "installment|")
/// Each service only touches its own slots, so syncing one never cancels the
/// other's reminders. Paper reminders are below zero (see
/// [paperReminderNotificationId]), outside every slot.
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

/// The slot of a reminder id (see [reminderNotificationId]); -1, no slot,
/// for a paper reminder.
int reminderSlot(int id) => id < 0 ? -1 : id % 10;

/// Paper reminders: the same hash, made negative so they never share an id
/// or a slot with the reminders above. [index] is the reminder (0–9).
int paperReminderNotificationId(String paperId, int index) =>
    -1 - reminderNotificationId(paperId, index);

bool isPaperReminderId(int id) => id < 0;

const warrantyReminderSlots = {0, 1, 2};
const subscriptionReminderSlots = {5, 6, 7, 8};
const installmentReminderSlots = {3, 4};
const customReminderSlot = 9;
