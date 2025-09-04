class WorkerBreak {
  final String id; // Long -> String
  final String workerId; // not always returned; keep for consistency
  final DateTime date;
  final String start; // "HH:mm"
  final String end; // "HH:mm"

  WorkerBreak({
    required this.id,
    required this.workerId,
    required this.date,
    required this.start,
    required this.end,
  });

  factory WorkerBreak.fromJson(Map<String, dynamic> m) {
    final start = (m['start'] ?? m['startTime']).toString();
    final end = (m['end'] ?? m['endTime']).toString();
    // some responses include date, some include from/to date — prefer 'date'
    final dateStr =
        (m['date'] ?? m['day'] ?? m['from'] ?? m['startDate'])!.toString();
    return WorkerBreak(
      id: m['id'].toString(),
      workerId: (m['workerId'] ?? '').toString(),
      date: DateTime.parse(dateStr),
      start: start,
      end: end,
    );
  }
}
