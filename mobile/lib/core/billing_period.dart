enum EffectiveChargeStatus { pending, overdue, paid, disregarded }

class BillingPeriod implements Comparable<BillingPeriod> {
  const BillingPeriod(this.year, this.month)
    : assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  factory BillingPeriod.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('Competência inválida: $value');
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    if (month < 1 || month > 12) {
      throw FormatException('Competência inválida: $value');
    }
    return BillingPeriod(year, month);
  }

  factory BillingPeriod.fromDate(DateTime date) =>
      BillingPeriod(date.year, date.month);

  BillingPeriod addMonths(int amount) {
    final zeroBased = year * 12 + (month - 1) + amount;
    return BillingPeriod(zeroBased ~/ 12, zeroBased % 12 + 1);
  }

  DateTime dueDate(int preferredDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, preferredDay.clamp(1, lastDay));
  }

  String get value =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  @override
  int compareTo(BillingPeriod other) =>
      (year * 12 + month).compareTo(other.year * 12 + other.month);

  @override
  bool operator ==(Object other) =>
      other is BillingPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => value;
}

EffectiveChargeStatus resolveChargeStatus({
  required DateTime dueDate,
  required DateTime today,
  required bool paid,
  bool disregarded = false,
}) {
  if (paid) return EffectiveChargeStatus.paid;
  if (disregarded) return EffectiveChargeStatus.disregarded;

  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final reference = DateTime(today.year, today.month, today.day);
  return due.isBefore(reference)
      ? EffectiveChargeStatus.overdue
      : EffectiveChargeStatus.pending;
}

String monthlyChargeDocumentId({
  required String studentId,
  required BillingPeriod period,
}) => 'mensalidade__${studentId}__${period.value}';
