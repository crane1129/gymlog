import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typo.dart';
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
  final double avgSetsPerSession;
  final String? mostTrainedExercise;

  const WorkoutStats({
    required this.totalSessions,
    required this.totalSets,
    required this.totalVolumeKg,
    this.avgSetsPerSession = 0,
    this.mostTrainedExercise,
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
  final setsByExercise = <String, int>{};
  for (final set in allSets) {
    setsBySession.putIfAbsent(set.sessionId, () => []).add(set);
    setsByExercise[set.exerciseId] = (setsByExercise[set.exerciseId] ?? 0) + 1;
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

  String? mostTrained;
  if (setsByExercise.isNotEmpty) {
    mostTrained = setsByExercise.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  return WorkoutStats(
    totalSessions: sessionsWithSets,
    totalSets: totalSets,
    totalVolumeKg: totalVolume,
    avgSetsPerSession: sessionsWithSets > 0 ? totalSets / sessionsWithSets : 0,
    mostTrainedExercise: mostTrained,
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
      exerciseCategory: exercise.category,
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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    statsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                      data: (stats) => _buildStatsRow(context, stats, settings, l10n),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    exerciseProgressAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                      data: (progressList) => _buildExerciseList(
                        context,
                        ref,
                        progressList,
                        settings,
                        l10n,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _buildFilterChip(context, ref, l10n.filterThisMonth, ProgressFilter.thisMonth, currentFilter),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(context, ref, l10n.filter3Months, ProgressFilter.threeMonths, currentFilter),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(context, ref, l10n.filter6Months, ProgressFilter.sixMonths, currentFilter),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(context, ref, l10n.filter12Months, ProgressFilter.twelveMonths, currentFilter),
          const SizedBox(width: AppSpacing.sm),
          _buildFilterChip(context, ref, l10n.filterAll, ProgressFilter.all, currentFilter),
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
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (_) {
        ref.read(progressFilterProvider.notifier).state = filter;
      },
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    WorkoutStats stats,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    if (stats.totalSessions == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noWorkoutRecordsForPeriod,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppTypo.bodyLg, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final unitLabel = settings.weightUnit == WeightUnit.kg ? 'kg' : 'lbs';
    final volume = settings.weightUnit == WeightUnit.lbs
        ? stats.totalVolumeKg * 2.20462
        : stats.totalVolumeKg;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: stats.totalSessions.toString(),
            label: l10n.totalWorkouts,
            icon: Icons.fitness_center_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            value: stats.totalSets.toString(),
            label: l10n.totalSetsLabel,
            icon: Icons.repeat_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            value: _formatNumber(volume),
            label: '$unitLabel ${l10n.volume}',
            icon: Icons.monitor_weight_rounded,
            color: AppColors.back,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseList(
    BuildContext context,
    WidgetRef ref,
    List<ExerciseProgress> progressList,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    if (progressList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(l10n.noExerciseData, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
      );
    }

    final useLbs = settings.weightUnit == WeightUnit.lbs;
    final expandedId = ref.watch(selectedExerciseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.exerciseProgress, style: AppTypo.title),
        const SizedBox(height: AppSpacing.sm),
        ...progressList.map((progress) {
          final isExpanded = expandedId == progress.exerciseId;
          return ExerciseProgressCard(
            progress: progress,
            useLbs: useLbs,
            isExpanded: isExpanded,
            onTap: () {
              ref.read(selectedExerciseProvider.notifier).state =
                  isExpanded ? null : progress.exerciseId;
            },
          );
        }),
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

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: TextStyle(
                fontSize: AppTypo.titleMd,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTypo.bodySm,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
