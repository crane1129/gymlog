import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/dashboard_stats.dart';
import 'providers/dashboard_provider.dart';
import 'widgets/summary_card.dart';
import 'widgets/weekly_chart.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
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
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCards(stats, settings, l10n, unitLabel, useLbs),
            const SizedBox(height: 24),
            _buildWeeklyChart(stats, useLbs),
            const SizedBox(height: 32),
            _buildStartWorkoutButton(context, l10n),
            const SizedBox(height: 16),
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
    final todayVolume = useLbs
        ? (stats.today.totalVolume * 2.20462).toStringAsFixed(0)
        : stats.today.totalVolume.toStringAsFixed(0);
    final weekVolume = useLbs
        ? (stats.thisWeek.totalVolume * 2.20462).toStringAsFixed(0)
        : stats.thisWeek.totalVolume.toStringAsFixed(0);
    final monthVolume = useLbs
        ? (stats.thisMonth.totalVolume * 2.20462).toStringAsFixed(0)
        : stats.thisMonth.totalVolume.toStringAsFixed(0);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SummaryCard(
            title: l10n.dashboardToday,
            icon: Icons.today,
            accentColor: AppColors.secondary,
            isHighlighted: stats.today.hasWorkout,
            mainValue: stats.today.hasWorkout
                ? l10n.workoutCompleted
                : l10n.noWorkoutYet,
            subValue: stats.today.hasWorkout
                ? '${l10n.setsCount(stats.today.totalSets)} • $todayVolume$unitLabel'
                : null,
          ),
          const SizedBox(width: 12),
          SummaryCard(
            title: l10n.dashboardThisWeek,
            icon: Icons.date_range,
            accentColor: AppColors.primary,
            mainValue: l10n.workoutsCount(stats.thisWeek.workoutCount),
            subValue: l10n.volumeFormat(weekVolume, unitLabel),
          ),
          const SizedBox(width: 12),
          SummaryCard(
            title: l10n.dashboardThisMonth,
            icon: Icons.calendar_month,
            accentColor: AppColors.chest,
            mainValue: l10n.workoutsCount(stats.thisMonth.workoutCount),
            subValue: l10n.volumeFormat(monthVolume, unitLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(DashboardStats stats, bool useLbs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: WeeklyBarChart(
          data: stats.last7Days,
          useLbs: useLbs,
        ),
      ),
    );
  }

  Widget _buildStartWorkoutButton(BuildContext context, AppLocalizations l10n) {
    return FilledButton.icon(
      onPressed: () {
        final sessionId = const Uuid().v4();
        context.push('/session/$sessionId');
      },
      icon: const Icon(Icons.play_arrow),
      label: Text(l10n.startWorkout),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 16,
        ),
      ),
    );
  }
}
