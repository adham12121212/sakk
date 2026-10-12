part of 'subscription_form_cubit.dart';

sealed class SubscriptionFormState {
  const SubscriptionFormState();
}

final class SubscriptionFormIdle extends SubscriptionFormState {
  const SubscriptionFormIdle();
}

final class SubscriptionFormBusy extends SubscriptionFormState {
  const SubscriptionFormBusy();
}

final class SubscriptionFormSaved extends SubscriptionFormState {
  const SubscriptionFormSaved(this.subscription);
  final UserSubscription subscription;
}

final class SubscriptionFormDeleted extends SubscriptionFormState {
  const SubscriptionFormDeleted();
}

final class SubscriptionFormFailure extends SubscriptionFormState {
  const SubscriptionFormFailure(this.message);
  final String message;
}
