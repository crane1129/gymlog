import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/workout_repository.dart';
import '../../domain/dashboard_stats.dart';

bool _isInDateRange(DateTime date, DateTime start, DateTime end) {
  return !date.isBefore(start) && date.isBefore(end);
}

List<WorkoutSet> _getSetsForSessions(
  List<WorkoutSession> sessions,
  Map<String, List<WorkoutSet>> setsBySession,
) {
  final sets = <WorkoutSet>[];
  for (final session in sessions) {
    sets.addAll(setsBySession[session.id] ?? []);
  }
  return sets;
}

double _calculateVolume(List<WorkoutSet> sets) {
  double volume = 0;
  for (final set in sets) {
    final weight = set.weightKg ?? 0;
    final reps = set.reps ?? 0;
    volume += weight * reps;
  }
  return volume;
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);
  final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));

  // Query from the earliest needed date (7 days ago or month start, whichever is earlier)
  final queryStart = sevenDaysAgo.isBefore(monthStart) ? sevenDaysAgo : monthStart;
  final allSessions = await repo.getSessionsByDateRange(queryStart, todayEnd);
  if (allSessions.isEmpty) {
    return DashboardStats.empty;
  }

  final sessionIds = allSessions.map((s) => s.id).toList();
  final allSets = await repo.getSetsBySessionIds(sessionIds);

  final setsBySession = <String, List<WorkoutSet>>{};
  for (final set in allSets) {
    setsBySession.putIfAbsent(set.sessionId, () => []).add(set);
  }

  // Today stats
  final todaySessions = allSessions.where((s) => _isInDateRange(s.date, todayStart, todayEnd)).toList();
  final todaySets = _getSetsForSessions(todaySessions, setsBySession);
  final todayVolume = _calculateVolume(todaySets);
  final todayDuration = todaySessions.isNotEmpty ? todaySessions.first.durationMinutes : null;

  final today = TodayStats(
    hasWorkout: todaySessions.isNotEmpty && todaySets.isNotEmpty,
    totalSets: todaySets.length,
    durationMinutes: todayDuration,
    totalVolume: todayVolume,
  );

  // This week stats
  final weekSessions = allSessions.where((s) => _isInDateRange(s.date, weekStart, todayEnd)).toList();
  final weekSets = _getSetsForSessions(weekSessions, setsBySession);
  final weekVolume = _calculateVolume(weekSets);
  final weekWorkoutCount = weekSessions.where((s) => (setsBySession[s.id]?.isNotEmpty ?? false)).length;

  final thisWeek = PeriodStats(
    workoutCount: weekWorkoutCount,
    totalVolume: weekVolume,
  );

  // This month stats
  final monthSessions = allSessions.where((s) => _isInDateRange(s.date, monthStart, todayEnd)).toList();
  final monthSets = _getSetsForSessions(monthSessions, setsBySession);
  final monthVolume = _calculateVolume(monthSets);
  final monthWorkoutCount = monthSessions.where((s) => (setsBySession[s.id]?.isNotEmpty ?? false)).length;

  final thisMonth = PeriodStats(
    workoutCount: monthWorkoutCount,
    totalVolume: monthVolume,
  );

  // Last 7 days for chart
  final last7Days = <DailyVolume>[];
  for (int i = 6; i >= 0; i--) {
    final dayStart = todayStart.subtract(Duration(days: i));
    final dayEnd = dayStart.add(const Duration(days: 1));

    final daySessions = allSessions.where((s) => _isInDateRange(s.date, dayStart, dayEnd)).toList();
    final daySets = _getSetsForSessions(daySessions, setsBySession);
    final dayVolume = _calculateVolume(daySets);

    last7Days.add(DailyVolume(
      date: dayStart,
      volume: dayVolume,
      setCount: daySets.length,
    ));
  }

  return DashboardStats(
    today: today,
    thisWeek: thisWeek,
    thisMonth: thisMonth,
    last7Days: last7Days,
  );
});
