import '../../../core/util/date_math.dart';
import 'entities/installment_plan.dart';
import 'entities/installment_terms.dart';
import 'entities/scheduled_payment.dart';

/// Money is worked out in piastres (hundredths) so rounding never drifts.
int _cents(double amount) => (amount * 100).round();
double _amount(int cents) => cents / 100;

/// The financed amount split evenly over [count] installments, rounded to
/// the piastre. Null when there's nothing to split.
double? suggestedInstallmentAmount(InstallmentTerms terms) =>
    suggestedAmountFor(terms.financedAmount, terms.installmentsCount);

double? suggestedAmountFor(double financedAmount, int count) {
  if (count <= 0 || financedAmount <= 0) return null;
  return _amount((_cents(financedAmount) / count).round());
}

/// When installment [index] (0 = the first) is due. The first is due on
/// [startDate]; each later one on [dueDayOfMonth] of the following months,
/// or the month's last day when it's shorter, without drifting
/// (31st → Feb 28 → Mar 31).
DateTime installmentDueDate(DateTime startDate, int dueDayOfMonth, int index) {
  if (index == 0) return dateOnly(startDate);
  return clampedDate(startDate.year, startDate.month + index, dueDayOfMonth);
}

/// Every installment of a plan with [terms], earliest first.
///
/// Each is [InstallmentTerms.installmentAmount]. When that's the financed
/// amount split evenly and rounded (within a piastre per installment), the
/// last one takes the rounding difference so they add up exactly.
List<ScheduledPayment> buildSchedule(InstallmentTerms terms) {
  final count = terms.installmentsCount;
  if (count <= 0 || terms.installmentAmount <= 0) return const [];
  final each = _cents(terms.installmentAmount);
  final financed = _cents(terms.financedAmount);
  var last = each;
  final difference = financed - each * count;
  if (difference != 0 && difference.abs() < count && each + difference > 0) {
    last = each + difference;
  }
  return [
    for (var i = 0; i < count; i++)
      ScheduledPayment(
        dueDate: installmentDueDate(terms.startDate, terms.dueDayOfMonth, i),
        amount: _amount(i == count - 1 ? last : each),
      ),
  ];
}

/// The fewest installments [plan] can be edited down to: the ones already
/// paid are kept.
int minimumInstallmentsCount(InstallmentPlan plan) =>
    plan.paidCount < 1 ? 1 : plan.paidCount;

/// The unpaid installments [plan] should have after its terms change to
/// [terms]. Paid installments are kept as they are.
///
/// With the same terms, the unpaid installments stay exactly as they are.
/// Otherwise the schedule is rebuilt from [terms] and each paid installment
/// keeps its place in it (paying the 1st and 3rd leaves the 2nd, 4th...
/// unpaid), so only the unpaid places get the new dates and amounts.
List<ScheduledPayment> unpaidScheduleForEdit(
  InstallmentPlan plan,
  InstallmentTerms terms,
) {
  if (terms == plan.terms) {
    return [
      for (final p in plan.unpaidPayments)
        ScheduledPayment(dueDate: p.dueDate, amount: p.amount),
    ];
  }
  final schedule = buildSchedule(terms);
  final paidPlaces = {
    for (var i = 0; i < plan.payments.length; i++)
      if (plan.payments[i].isPaid) i,
  };
  final needed = terms.installmentsCount - plan.paidCount;
  final unpaid = <ScheduledPayment>[];
  for (var i = 0; i < schedule.length && unpaid.length < needed; i++) {
    if (!paidPlaces.contains(i)) unpaid.add(schedule[i]);
  }
  return unpaid;
}
