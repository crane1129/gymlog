class TodayStats {
  final bool hasWorkout;
  final int totalSets;
  final int? durationMinutes;
  final double totalVolume;

  const TodayStats({
    required this.hasWorkout,
    required this.totalSets,
    this.durationMinutes,
    required this.totalVolume,
  });

  static const empty = TodayStats(
    hasWorkout: false,
    totalSets: 0,
    totalVolume: 0,
  );
}

class PeriodStats {
  final int workoutCount;
  final double totalVolume;

  const PeriodStats({
    required this.workoutCount,
    required this.totalVolume,
  });

  static const empty = PeriodStats(workoutCount: 0, totalVolume: 0);
}

class DailyVolume {
  final DateTime date;
  final double volume;
  final int setCount;

  const DailyVolume({
    required this.date,
    required this.volume,
    required this.setCount,
  });
}

class DashboardStats {
  final TodayStats today;
  final PeriodStats thisWeek;
  final PeriodStats thisMonth;
  final List<DailyVolume> last7Days;

  const DashboardStats({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.last7Days,
  });

  static DashboardStats get empty => DashboardStats(
        today: TodayStats.empty,
        thisWeek: PeriodStats.empty,
        thisMonth: PeriodStats.empty,
        last7Days: [],
      );
}
