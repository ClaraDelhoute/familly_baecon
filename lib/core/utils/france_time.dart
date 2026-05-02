DateTime toFranceTime(DateTime date) {
  final utc = date.toUtc();
  return utc.add(Duration(hours: _isFranceDst(utc) ? 2 : 1));
}

bool _isFranceDst(DateTime utc) {
  final start = _lastSundayUtc(utc.year, 3).add(const Duration(hours: 1));
  final end = _lastSundayUtc(utc.year, 10).add(const Duration(hours: 1));
  return utc.isAfter(start) && utc.isBefore(end);
}

DateTime _lastSundayUtc(int year, int month) {
  final firstNextMonth = month == 12
      ? DateTime.utc(year + 1, 1, 1)
      : DateTime.utc(year, month + 1, 1);
  final lastDayOfMonth = firstNextMonth.subtract(const Duration(days: 1));
  return lastDayOfMonth.subtract(Duration(days: lastDayOfMonth.weekday % 7));
}
