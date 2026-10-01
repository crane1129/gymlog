import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typo.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../exercise/data/exercise_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/dashboard_stats.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/summary_card.dart';
import 'widgets/weekly_chart.dart';

final _recentExerciseIdsProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(exerciseRepositoryProvider);
  return repo.watchRecentExerciseIds(limit: 5);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final dashboardStats = ref.watch(dashboardStatsProvider);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(),
      ),
      body: dashboardStats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (stats) => _buildDashboard(context, ref, stats, settings, l10n),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    DashboardStats stats,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    final useLbs = settings.weightUnit == WeightUnit.lbs;
    final unitLabel = useLbs ? 'lbs' : 'kg';

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(_recentExerciseIdsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(context, stats, l10n, unitLabel, useLbs),
            const SizedBox(height: AppSpacing.lg),
            _buildSummaryCards(stats, settings, l10n, unitLabel, useLbs),
            const SizedBox(height: AppSpacing.lg),
            _buildWeeklyChart(stats, useLbs),
            const SizedBox(height: AppSpacing.lg),
            _buildRecentExercises(context, ref, l10n, settings),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    DashboardStats stats,
    AppLocalizations l10n,
    String unitLabel,
    bool useLbs,
  ) {
    final todayVolume = useLbs
        ? (stats.today.totalVolume * 2.20462).toStringAsFixed(0)
        : stats.today.totalVolume.toStringAsFixed(0);

    return Card(
      color: AppColors.primary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  stats.today.hasWorkout ? Icons.check_circle : Icons.fitness_center,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 28,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  l10n.dashboardToday,
                  style: TextStyle(
                    fontSize: AppTypo.bodyLg,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              stats.today.hasWorkout
                  ? l10n.workoutCompleted
                  : l10n.noWorkoutYet,
              style: const TextStyle(
                fontSize: AppTypo.titleLg,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (stats.today.hasWorkout) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.setsCount(stats.today.totalSets)} · $todayVolume$unitLabel',
                style: TextStyle(
                  fontSize: AppTypo.bodyMd,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final sessionId = const Uuid().v4();
                  context.push('/session/$sessionId');
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.startWorkout),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(
    DashboardStats stats,
    AppSettings settings,
    AppLocalizations l10n,
    String unitLabel,
    bool useLbs,
  ) {
    final weekVolume = useLbs
        ? (stats.thisWeek.totalVolume * 2.20462).toStringAsFixed(0)
        : stats.thisWeek.totalVolume.toStringAsFixed(0);
    final monthVolume = useLbs
        ? (stats.thisMonth.totalVolume * 2.20462).toStringAsFixed(0)
        : stats.thisMonth.totalVolume.toStringAsFixed(0);

    return Row(
      children: [
        Expanded(
          child: SummaryCard(
            title: l10n.dashboardThisWeek,
            icon: Icons.date_range,
            accentColor: AppColors.primary,
            mainValue: l10n.workoutsCount(stats.thisWeek.workoutCount),
            subValue: l10n.volumeFormat(weekVolume, unitLabel),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: SummaryCard(
            title: l10n.dashboardThisMonth,
            icon: Icons.calendar_month,
            accentColor: AppColors.chest,
            mainValue: l10n.workoutsCount(stats.thisMonth.workoutCount),
            subValue: l10n.volumeFormat(monthVolume, unitLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(DashboardStats stats, bool useLbs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: WeeklyBarChart(
          data: stats.last7Days,
          useLbs: useLbs,
        ),
      ),
    );
  }

  Widget _buildRecentExercises(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AppSettings settings,
  ) {
    final recentIdsAsync = ref.watch(_recentExerciseIdsProvider);
    final exercisesAsync = ref.watch(
      StreamProvider<List<Exercise>>((ref) {
        return ref.watch(exerciseRepositoryProvider).watchAllExercises();
      }),
    );

    return recentIdsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recentIds) {
        if (recentIds.isEmpty) return const SizedBox.shrink();
        return exercisesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (allExercises) {
            final exerciseMap = {for (final e in allExercises) e.id: e};
            final recentExercises = recentIds
                .map((id) => exerciseMap[id])
                .whereType<Exercise>()
                .toList();
            if (recentExercises.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.recentExercisesTitle,
                  style: const TextStyle(
                    fontSize: AppTypo.titleSm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentExercises.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final exercise = recentExercises[index];
                      return _buildRecentExerciseChip(
                        exercise, settings.locale.languageCode == 'ko',
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecentExerciseChip(Exercise exercise, bool isKorean) {
    final name = DefaultExerciseHelper.getDisplayName(
      exercise.id,
      exercise.name,
      isKorean,
    );
    final categoryColor = AppColors.getCategoryColor(exercise.category);

    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.mdAll,
            ),
            child: Center(
              child: Text(
                name[0],
                style: TextStyle(
                  fontSize: AppTypo.titleMd,
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            name,
            style: const TextStyle(fontSize: AppTypo.bodySm),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
