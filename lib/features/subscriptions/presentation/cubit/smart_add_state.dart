part of 'smart_add_cubit.dart';

sealed class SmartAddState {
  const SmartAddState();
}

final class SmartAddIdle extends SmartAddState {
  const SmartAddIdle();
}

final class SmartAddReading extends SmartAddState {
  const SmartAddReading();
}

/// Read: open the form with [args] for the user to review.
final class SmartAddReady extends SmartAddState {
  const SmartAddReady(this.args);
  final SubscriptionFormArgs args;
}

final class SmartAddFailure extends SmartAddState {
  const SmartAddFailure(this.message);
  final String message;
}
