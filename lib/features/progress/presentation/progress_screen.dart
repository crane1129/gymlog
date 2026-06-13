import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../exercise/data/exercise_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../../workout/data/workout_repository.dart';
import '../domain/exercise_progress.dart';
import 'widgets/exercise_progress_card.dart';

enum ProgressFilter { thisMonth, threeMonths, sixMonths, twelveMonths, all }

class WorkoutStats {
  final int totalSessions;
  final int totalSets;
  final double totalVolumeKg;

  const WorkoutStats({
    required this.totalSessions,
    required this.totalSets,
    required this.totalVolumeKg,
  });

  static const empty = WorkoutStats(
    totalSessions: 0,
    totalSets: 0,
    totalVolumeKg: 0,
  );
}

final progressFilterProvider = StateProvider<ProgressFilter>((ref) {
  return ProgressFilter.all;
});

final selectedExerciseProvider = StateProvider<String?>((ref) => null);

DateTime _getStartDate(ProgressFilter filter) {
  final now = DateTime.now();
  switch (filter) {
    case ProgressFilter.thisMonth:
      return DateTime(now.year, now.month, 1);
    case ProgressFilter.threeMonths:
      return DateTime(now.year, now.month - 2, 1);
    case ProgressFilter.sixMonths:
      return DateTime(now.year, now.month - 5, 1);
    case ProgressFilter.twelveMonths:
      return DateTime(now.year - 1, now.month, 1);
    case ProgressFilter.all:
      return DateTime(2020, 1, 1);
  }
}

final workoutStatsProvider = FutureProvider.autoDispose<WorkoutStats>((ref) async {
  final repo = ref.watch(workoutRepositoryProvider);
  final filter = ref.watch(progressFilterProvider);

  final now = DateTime.now();
  final startDate = _getStartDate(filter);
  final endDate = now.add(const Duration(days: 1));

  final sessions = await repo.getSessionsByDateRange(startDate, endDate);

  if (sessions.isEmpty) {
    return WorkoutStats.empty;
  }

  final sessionIds = sessions.map((s) => s.id).toList();
  final allSets = await repo.getSetsBySessionIds(sessionIds);

  final setsBySession = <String, List<dynamic>>{};
  for (final set in allSets) {
    setsBySession.putIfAbsent(set.sessionId, () => []).add(set);
  }

  int sessionsWithSets = 0;
  int totalSets = 0;
  double totalVolume = 0;

  for (final session in sessions) {
    final sets = setsBySession[session.id] ?? [];
    if (sets.isNotEmpty) {
      sessionsWithSets++;
      totalSets += sets.length;
      for (final set in sets) {
        final weight = set.weightKg ?? 0;
        final reps = set.reps ?? 0;
        totalVolume += weight * reps;
      }
    }
  }

  return WorkoutStats(
    totalSessions: sessionsWithSets,
    totalSets: totalSets,
    totalVolumeKg: totalVolume,
  );
});

final exerciseProgressProvider = FutureProvider.autoDispose<List<ExerciseProgress>>((ref) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);
  final filter = ref.watch(progressFilterProvider);
  final settings = ref.watch(settingsProvider);
  final isKorean = settings.locale.languageCode == 'ko';

  final now = DateTime.now();
  final startDate = _getStartDate(filter);
  final endDate = now.add(const Duration(days: 1));

  final setsByExercise = await workoutRepo.getSetsByExercisesWithSessionDate(startDate, endDate);
  if (setsByExercise.isEmpty) return [];

  final exercises = <String, Exercise>{};
  for (final exerciseId in setsByExercise.keys) {
    final exercise = await exerciseRepo.getExerciseById(exerciseId);
    if (exercise != null) {
      exercises[exerciseId] = exercise;
    }
  }

  final progressList = <ExerciseProgress>[];

  for (final entry in setsByExercise.entries) {
    final exerciseId = entry.key;
    final setsWithDates = entry.value;
    final exercise = exercises[exerciseId];

    if (exercise == null || setsWithDates.isEmpty) continue;

    final exerciseName = DefaultExerciseHelper.getDisplayName(
      exerciseId,
      exercise.name,
      isKorean,
    );

    final hasWeight = setsWithDates.any((s) => (s.set.weightKg ?? 0) > 0);
    final hasReps = setsWithDates.any((s) => (s.set.reps ?? 0) > 0);
    final hasDuration = setsWithDates.any((s) => (s.set.durationSeconds ?? 0) > 0);
    final hasDistance = setsWithDates.any((s) => (s.set.distanceKm ?? 0) > 0);

    ExerciseDataType dataType;
    if (hasDuration || hasDistance) {
      dataType = ExerciseDataType.cardio;
    } else if (hasWeight && hasReps) {
      dataType = ExerciseDataType.weightAndReps;
    } else if (hasWeight) {
      dataType = ExerciseDataType.weightOnly;
    } else {
      dataType = ExerciseDataType.repsOnly;
    }

    final setsByDate = <DateTime, List<WorkoutSet>>{};
    for (final item in setsWithDates) {
      final dateKey = DateTime(item.sessionDate.year, item.sessionDate.month, item.sessionDate.day);
      setsByDate.putIfAbsent(dateKey, () => []).add(item.set);
    }

    final sortedDates = setsByDate.keys.toList()..sort();
    final points = <ExerciseProgressPoint>[];

    for (final date in sortedDates) {
      final daySets = setsByDate[date]!;
      double? maxWeight;
      int? maxReps;
      double totalVolume = 0;
      int? maxDuration;
      double? maxDistance;
      int totalDuration = 0;
      double totalDistance = 0;

      for (final set in daySets) {
        final weight = set.weightKg ?? 0;
        final reps = set.reps ?? 0;
        final duration = set.durationSeconds ?? 0;
        final distance = set.distanceKm ?? 0;

        if (weight > 0) {
          if (maxWeight == null || weight > maxWeight) {
            maxWeight = weight;
          }
        }
        if (reps > 0) {
          if (maxReps == null || reps > maxReps) {
            maxReps = reps;
          }
        }
        if (duration > 0) {
          if (maxDuration == null || duration > maxDuration) {
            maxDuration = duration;
          }
          totalDuration += duration;
        }
        if (distance > 0) {
          if (maxDistance == null || distance > maxDistance) {
            maxDistance = distance;
          }
          totalDistance += distance;
        }
        totalVolume += weight * reps;
      }

      points.add(ExerciseProgressPoint(
        date: date,
        maxWeight: maxWeight,
        maxReps: maxReps,
        totalVolume: totalVolume,
        maxDurationSeconds: maxDuration,
        maxDistanceKm: maxDistance,
        totalDurationSeconds: totalDuration > 0 ? totalDuration : null,
        totalDistanceKm: totalDistance > 0 ? totalDistance : null,
        setCount: daySets.length,
      ));
    }

    double? currentMaxWeight;
    int? currentMaxReps;
    double? previousMaxWeight;
    int? previousMaxReps;
    int? currentMaxDuration;
    double? currentMaxDistance;
    int? previousMaxDuration;
    double? previousMaxDistance;

    if (points.isNotEmpty) {
      currentMaxWeight = points.last.maxWeight;
      currentMaxReps = points.last.maxReps;
      currentMaxDuration = points.last.maxDurationSeconds;
      currentMaxDistance = points.last.maxDistanceKm;

      if (points.length >= 2) {
        previousMaxWeight = points[points.length - 2].maxWeight;
        previousMaxReps = points[points.length - 2].maxReps;
        previousMaxDuration = points[points.length - 2].maxDurationSeconds;
        previousMaxDistance = points[points.length - 2].maxDistanceKm;
      }
    }

    progressList.add(ExerciseProgress(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      dataType: dataType,
      points: points,
      currentMaxWeight: currentMaxWeight,
      currentMaxReps: currentMaxReps,
      previousMaxWeight: previousMaxWeight,
      previousMaxReps: previousMaxReps,
      currentMaxDuration: currentMaxDuration,
      currentMaxDistance: currentMaxDistance,
      previousMaxDuration: previousMaxDuration,
      previousMaxDistance: previousMaxDistance,
    ));
  }

  progressList.sort((a, b) => b.points.length.compareTo(a.points.length));

  return progressList;
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final statsAsync = ref.watch(workoutStatsProvider);
    final exerciseProgressAsync = ref.watch(exerciseProgressProvider);
    final currentFilter = ref.watch(progressFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progress),
      ),
      body: Column(
        children: [
          _buildFilterChips(context, ref, l10n, currentFilter),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(workoutStatsProvider);
                ref.invalidate(exerciseProgressProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    statsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                      data: (stats) => _buildStatsView(context, stats, settings, l10n),
                    ),
                    const SizedBox(height: 24),
                    exerciseProgressAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                      data: (progressList) => _buildExerciseProgressSection(
                        context,
                        ref,
                        progressList,
                        settings,
                        l10n,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ProgressFilter currentFilter,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip(
            context,
            ref,
            l10n.filterThisMonth,
            ProgressFilter.thisMonth,
            currentFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            l10n.filter3Months,
            ProgressFilter.threeMonths,
            currentFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            l10n.filter6Months,
            ProgressFilter.sixMonths,
            currentFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            l10n.filter12Months,
            ProgressFilter.twelveMonths,
            currentFilter,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context,
            ref,
            l10n.filterAll,
            ProgressFilter.all,
            currentFilter,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    ProgressFilter filter,
    ProgressFilter currentFilter,
  ) {
    final isSelected = filter == currentFilter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        ref.read(progressFilterProvider.notifier).state = filter;
      },
    );
  }

  Widget _buildStatsView(
    BuildContext context,
    WorkoutStats stats,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final unitLabel = settings.weightUnit == WeightUnit.kg ? 'kg' : 'lbs';
    final volume = settings.weightUnit == WeightUnit.lbs
        ? stats.totalVolumeKg * 2.20462
        : stats.totalVolumeKg;

    if (stats.totalSessions == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bar_chart,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.isKorean
                  ? '이 기간의 운동 기록이 없습니다'
                  : 'No workout records for this period',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.totalStats,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.fitness_center,
                value: stats.totalSessions.toString(),
                label: l10n.totalWorkouts,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.repeat,
                value: stats.totalSets.toString(),
                label: l10n.totalSetsLabel,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          context,
          icon: Icons.monitor_weight,
          value: '${_formatNumber(volume)} $unitLabel',
          label: l10n.totalVolume,
          color: Colors.orange,
          isWide: true,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isWide = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: isWide ? 28 : 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseProgressSection(
    BuildContext context,
    WidgetRef ref,
    List<ExerciseProgress> progressList,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    if (progressList.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.exerciseProgress,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                l10n.noExerciseData,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }

    final useLbs = settings.weightUnit == WeightUnit.lbs;
    final selectedId = ref.watch(selectedExerciseProvider);

    final selected = progressList.firstWhere(
      (p) => p.exerciseId == selectedId,
      orElse: () => progressList.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exerciseProgress,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        DropdownMenu<String>(
          initialSelection: selected.exerciseId,
          expandedInsets: EdgeInsets.zero,
          label: Text(l10n.selectExercise),
          onSelected: (value) {
            if (value != null) {
              ref.read(selectedExerciseProvider.notifier).state = value;
            }
          },
          dropdownMenuEntries: (List.of(progressList)
                ..sort((a, b) => a.exerciseName.compareTo(b.exerciseName)))
              .map((p) => DropdownMenuEntry<String>(
                    value: p.exerciseId,
                    label: p.exerciseName,
                  ))
              .toList(),
        ),
        const SizedBox(height: 12),
        ExerciseProgressCard(
          progress: selected,
          useLbs: useLbs,
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }
}
