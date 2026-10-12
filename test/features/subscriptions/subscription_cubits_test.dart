import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/core/error/failure.dart';
import 'package:sakk/features/subscriptions/domain/entities/billing_cycle.dart';
import 'package:sakk/features/subscriptions/domain/entities/catalog_service.dart';
import 'package:sakk/features/subscriptions/domain/entities/subscription_category.dart';
import 'package:sakk/features/subscriptions/domain/entities/user_subscription.dart';
import 'package:sakk/features/subscriptions/domain/usecase/add_subscription_usecase.dart';
import 'package:sakk/features/subscriptions/domain/usecase/delete_subscription_usecase.dart';
import 'package:sakk/features/subscriptions/domain/usecase/get_subscriptions_usecase.dart';
import 'package:sakk/features/subscriptions/domain/usecase/update_subscription_usecase.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/catalog_state.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscription_form_cubit.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:sakk/features/subscriptions/presentation/cubit/subscriptions_state.dart';

UserSubscription sub(String id, DateTime renewal, {double price = 100, String currency = 'EGP'}) =>
    UserSubscription(
      id: id,
      customName: id,
      price: price,
      currency: currency,
      billingCycle: BillingCycle.monthly,
      nextRenewalDate: renewal,
    );

class _FakeGet implements GetSubscriptionsUseCase {
  Either<Failure, List<UserSubscription>> result = const Right([]);
  @override
  Future<Either<Failure, List<UserSubscription>>> call() async => result;
}

/// Records which write ran and answers with an echo of the saved row.
class _FakeWrites {
  Failure? failWith;
  final calls = <String>[];

  Future<Either<Failure, UserSubscription>> _save(String op, String id, double price, DateTime renewal) async {
    calls.add(op);
    if (failWith != null) return Left(failWith!);
    return Right(sub(id, renewal, price: price));
  }
}

class _FakeDelete implements DeleteSubscriptionUseCase {
  Failure? failWith;
  @override
  Future<Either<Failure, void>> call(String id) async => failWith != null ? Left(failWith!) : const Right(null);
}

class _FakeAdd implements AddSubscriptionUseCase {
  _FakeAdd(this.writes);
  final _FakeWrites writes;
  @override
  Future<Either<Failure, UserSubscription>> call({
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  }) =>
      writes._save('add', 'new', price, nextRenewalDate);
}

class _FakeUpdate implements UpdateSubscriptionUseCase {
  _FakeUpdate(this.writes);
  final _FakeWrites writes;
  @override
  Future<Either<Failure, UserSubscription>> call({
    required String id,
    String? catalogId,
    String? customName,
    String? planName,
    required SubscriptionCategory category,
    required double price,
    required String currency,
    required BillingCycle billingCycle,
    required DateTime nextRenewalDate,
    String? paymentMethod,
    String? notes,
  }) =>
      writes._save('update', id, price, nextRenewalDate);
}

void main() {
  group('SubscriptionsCubit', () {
    test('refresh sorts by nearest renewal and marks the list loaded', () async {
      final get = _FakeGet()
        ..result = Right([sub('late', DateTime(2026, 12, 1)), sub('soon', DateTime(2026, 10, 14))]);
      final cubit = SubscriptionsCubit(get);
      await cubit.refresh();
      expect(cubit.state.subscriptions.map((s) => s.id), ['soon', 'late']);
      expect(cubit.state.hasLoadedOnce, isTrue);
      expect(cubit.state.isLoading, isFalse);

      // Already loaded: loadIfNeeded does nothing.
      get.result = const Right([]);
      await cubit.loadIfNeeded();
      expect(cubit.state.subscriptions, hasLength(2));
    });

    test('a failed load keeps the error for the screen', () async {
      final cubit = SubscriptionsCubit(_FakeGet()..result = const Left(NetworkFailure(NetworkFailure.noConnectionMessage)));
      await cubit.refresh();
      expect(cubit.state.error, NetworkFailure.noConnectionMessage);
      expect(cubit.state.hasLoadedOnce, isFalse);
    });

    test('upsert replaces and re-sorts; remove and reset clear', () async {
      final cubit = SubscriptionsCubit(
        _FakeGet()..result = Right([sub('a', DateTime(2026, 10, 20)), sub('b', DateTime(2026, 11, 20))]),
      );
      await cubit.refresh();
      cubit.upsert(sub('b', DateTime(2026, 10, 15)));
      expect(cubit.state.subscriptions.map((s) => s.id), ['b', 'a']);
      cubit.upsert(sub('c', DateTime(2026, 12, 1)));
      expect(cubit.state.subscriptions.map((s) => s.id), ['b', 'a', 'c']);
      cubit.remove('a');
      expect(cubit.state.subscriptions.map((s) => s.id), ['b', 'c']);
      cubit.reset();
      expect(cubit.state.subscriptions, isEmpty);
      expect(cubit.state.hasLoadedOnce, isFalse);
    });

    test('nextRenewal skips renewals that already passed', () {
      // On the state directly: the cubit itself rolls passed dates forward.
      final state = SubscriptionsState(subscriptions: [
        sub('past', DateTime(2026, 10, 1)),
        sub('next', DateTime(2026, 10, 20)),
      ]);
      expect(state.nextRenewal(DateTime(2026, 10, 12))?.id, 'next');
      expect(state.nextRenewal(DateTime(2026, 10, 21)), isNull);
    });
  });

  group('SubscriptionFormCubit', () {
    late _FakeWrites writes;
    late _FakeDelete delete;
    late SubscriptionsCubit list;
    late SubscriptionFormCubit form;

    setUp(() async {
      writes = _FakeWrites();
      delete = _FakeDelete();
      list = SubscriptionsCubit(_FakeGet()..result = Right([sub('old', DateTime(2026, 11, 1))]));
      await list.refresh();
      form = SubscriptionFormCubit(_FakeAdd(writes), _FakeUpdate(writes), delete, list);
    });

    Future<void> save({String? id}) => form.save(
          id: id,
          customName: 'Gym',
          category: SubscriptionCategory.other,
          price: 500,
          currency: 'EGP',
          billingCycle: BillingCycle.monthly,
          nextRenewalDate: DateTime(2026, 10, 20),
        );

    test('adding saves and puts the new row in the shared list', () async {
      await save();
      expect(writes.calls, ['add']);
      expect(form.state, isA<SubscriptionFormSaved>());
      expect(list.state.subscriptions.map((s) => s.id), ['new', 'old']);
    });

    test('with an id it updates instead', () async {
      await save(id: 'old');
      expect(writes.calls, ['update']);
      expect(list.state.subscriptions.single.price, 500);
    });

    test('a failure is reported and the list is untouched', () async {
      writes.failWith = const NetworkFailure(NetworkFailure.noConnectionMessage);
      await save();
      final state = form.state;
      expect(state, isA<SubscriptionFormFailure>());
      expect((state as SubscriptionFormFailure).message, NetworkFailure.noConnectionMessage);
      expect(list.state.subscriptions.map((s) => s.id), ['old']);
    });

    test('delete removes the row from the shared list', () async {
      await form.delete('old');
      expect(form.state, isA<SubscriptionFormDeleted>());
      expect(list.state.subscriptions, isEmpty);

      delete.failWith = const ServerFailure('boom');
      await form.delete('x');
      expect(form.state, isA<SubscriptionFormFailure>());
    });
  });

  test('catalog search matches anywhere in the name, ignoring case', () {
    const state = CatalogState(services: [
      CatalogService(id: '1', name: 'Netflix'),
      CatalogService(id: '2', name: 'Shahid'),
      CatalogService(id: '3', name: 'YouTube Premium'),
    ]);
    expect(state.filtered, hasLength(3));
    expect(state.copyWith(query: 'FLIX').filtered.single.name, 'Netflix');
    expect(state.copyWith(query: ' premium ').filtered.single.name, 'YouTube Premium');
    expect(state.copyWith(query: 'zzz').filtered, isEmpty);
  });
}
