class AbsencePeriod {
  final DateTime? start;
  final DateTime? end;

  AbsencePeriod({this.start, this.end});

  /// Retourne true si une période est définie (start et end non null)
  bool get isDefined => start != null && end != null;

  /// Retourne true si on est actuellement dans la période d'absence
  bool isActive([DateTime? at]) {
    final now = at ?? DateTime.now();
    if (start == null && end == null) return false;
    if (start != null && end != null) return !now.isBefore(start!) && !now.isAfter(end!);
    if (start != null && end == null) return !now.isBefore(start!);
    if (start == null && end != null) return !now.isAfter(end!);
    return false;
  }

  Map<String, dynamic> toJson() => {
        'start': start?.toIso8601String(),
        'end': end?.toIso8601String(),
      };

  factory AbsencePeriod.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AbsencePeriod();
    DateTime? parse(String? s) => s == null ? null : DateTime.tryParse(s);
    return AbsencePeriod(start: parse(json['start'] as String?), end: parse(json['end'] as String?));
  }

  @override
  String toString() => 'AbsencePeriod(start=$start, end=$end)';
}

