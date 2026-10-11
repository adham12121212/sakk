import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure.dart';
import '../../../products/presentation/cubit/product_cubit.dart';
import '../../data/household_repo.dart';
import '../../domain/household.dart';

class HouseholdState extends Equatable {
  const HouseholdState({
    this.household,
    this.members = const [],
    this.isLoading = false,
    this.isBusy = false,
    this.error,
  });

  final Household? household;
  final List<HouseholdMember> members;
  final bool isLoading;

  /// An action (create, join, leave...) is running.
  final bool isBusy;
  final String? error;

  bool isOwner(String? userId) => members.any((m) => m.userId == userId && m.isOwner);

  /// Who added a product, for "Added by ..." on shared products.
  String? nameOf(String? userId) => members.where((m) => m.userId == userId).firstOrNull?.displayName;

  @override
  List<Object?> get props => [household, members, isLoading, isBusy, error];
}

/// App-wide: Profile manages the household; product screens read member
/// names from it.
class HouseholdCubit extends Cubit<HouseholdState> {
  HouseholdCubit(this._repo, this._productsCubit) : super(const HouseholdState());

  final HouseholdRepo _repo;
  final ProductsCubit _productsCubit;

  Future<void> load() async {
    emit(HouseholdState(household: state.household, members: state.members, isLoading: true));
    final result = await _repo.load();
    if (isClosed) return;
    result.fold(
      (failure) => emit(HouseholdState(household: state.household, members: state.members, error: failure.message)),
      (data) => emit(HouseholdState(household: data.$1, members: data.$2)),
    );
  }

  Future<bool> create(String name, String displayName) =>
      _act(() => _repo.create(name: name, displayName: displayName));

  Future<bool> join(String inviteCode, String displayName) =>
      _act(() => _repo.join(inviteCode: inviteCode, displayName: displayName));

  Future<bool> leave() => _act(_repo.leave);

  Future<bool> removeMember(String userId) => _act(() => _repo.removeMember(userId));

  Future<bool> regenerateInviteCode() => _act(_repo.regenerateInviteCode, refreshProducts: false);

  /// Signed out: forget the old account's household.
  void reset() => emit(const HouseholdState());

  /// Runs an action, then reloads the household and (since who can see what
  /// changed) the product list. Returns whether it worked.
  Future<bool> _act(Future<Either<Failure, void>> Function() action, {bool refreshProducts = true}) async {
    emit(HouseholdState(household: state.household, members: state.members, isBusy: true));
    final failure = (await action()).fold((f) => f, (_) => null);
    if (isClosed) return failure == null;
    if (failure != null) {
      emit(HouseholdState(household: state.household, members: state.members, error: failure.message));
      return false;
    }
    await load();
    if (refreshProducts) await _productsCubit.refresh();
    return true;
  }
}
