import 'package:intl/intl.dart';

/// Weight: 850 → "850g", 3200 → "3.2kg" (trailing .0 stripped), matching the plan.
String fmtWeight(int grams) {
  if (grams >= 1000) {
    final kg = (grams / 1000).toStringAsFixed(1);
    return '${kg.endsWith('.0') ? kg.substring(0, kg.length - 2) : kg}kg';
  }
  return '${grams}g';
}

/// Price: whole numbers show no decimals, otherwise two. e.g. 39 → "€39",
/// 42.5 → "€42.50".
String fmtPrice(num n) =>
    '€${n % 1 == 0 ? n.toStringAsFixed(0) : n.toStringAsFixed(2)}';

// Use the default (en_US) locale, which intl always has data for. A named
// locale like 'en_GB' would need initializeDateFormatting() and otherwise
// throws LocaleDataException the first time a date is formatted. The patterns
// are explicit, so the rendered output ("05 Aug 2026") is unchanged.
final _dm = DateFormat('dd MMM');
final _dmy = DateFormat('dd MMM yyyy');

/// "05 Aug 2026" for a single day, "05 Aug – 07 Aug 2026" for a range.
String? fmtDateRange(DateTime? start, DateTime? end) {
  if (start == null) return null;
  if (end == null || _sameDay(start, end)) return _dmy.format(start);
  return '${_dm.format(start)} – ${_dmy.format(end)}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

enum CountdownState { upcoming, ongoing, past }

class Countdown {
  const Countdown(this.label, this.state);
  final String label;
  final CountdownState state;
}

/// Days until a trip. Pure w.r.t. [now] so it's testable.
Countdown? daysUntil(DateTime? start, DateTime? end, {DateTime? now}) {
  if (start == null) return null;
  final today = _dateOnly(now ?? DateTime.now());
  final s = _dateOnly(start);
  final e = _dateOnly(end ?? start);
  final toStart = s.difference(today).inDays;
  final toEnd = e.difference(today).inDays;
  if (toStart > 0) {
    return Countdown(
        'in $toStart day${toStart == 1 ? '' : 's'}', CountdownState.upcoming);
  }
  if (toEnd >= 0) return const Countdown('happening now', CountdownState.ongoing);
  return const Countdown('past', CountdownState.past);
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
