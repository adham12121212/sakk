import 'package:flutter_test/flutter_test.dart';
import 'package:sakk/features/household/domain/household.dart';
import 'package:sakk/features/household/presentation/cubit/household_cubit.dart';

void main() {
  const state = HouseholdState(
    household: Household(id: 'h', name: 'Family', inviteCode: 'A1B2C3D4E5'),
    members: [
      HouseholdMember(userId: 'ahmed', displayName: 'Ahmed', isOwner: true),
      HouseholdMember(userId: 'mona', displayName: 'Mona', isOwner: false),
    ],
  );

  test('names products by who added them', () {
    expect(state.nameOf('mona'), 'Mona');
    expect(state.nameOf('someone-who-left'), isNull);
  });

  test('knows who the owner is', () {
    expect(state.isOwner('ahmed'), isTrue);
    expect(state.isOwner('mona'), isFalse);
  });
}
