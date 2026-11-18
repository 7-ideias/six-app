typedef CockpitPoint =
    ({
      int time,
      int observedMs,
      int total,
      int clientErrors,
      int serverErrors,
      int? p50,
      int? p95,
    });
typedef CockpitEvent = ({int time, String type, String? source});

class AdminCockpitSnapshot {
  AdminCockpitSnapshot.fromJson(Map<String, dynamic> json)
    : collectedAt = json['collectedAt'] as int,
      startedAt = json['startedAt'] as int,
      observedMs = json['observedMs'] as int,
      total = json['total'] as int,
      serverErrors = json['serverErrors'] as int,
      p95 = json['p95'] as int?,
      points = [
        for (final p in json['points'] as List)
          (
            time: p['time'] as int,
            observedMs: p['observedMs'] as int,
            total: p['total'] as int,
            clientErrors: p['clientErrors'] as int,
            serverErrors: p['serverErrors'] as int,
            p50: p['p50'] as int?,
            p95: p['p95'] as int?,
          ),
      ],
      events = [
        for (final e in json['events'] as List)
          (
            time: e['time'] as int,
            type: e['type'] as String,
            source: e['source'] as String?,
          ),
      ];
  final int collectedAt, startedAt, observedMs, total, serverErrors;
  final int? p95;
  final List<CockpitPoint> points;
  final List<CockpitEvent> events;
}
