import 'package:flutter/material.dart';

import '../../../../core/constants/exercise_category.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_radius.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typo.dart';
import '../../domain/exercise_progress.dart';
import 'exercise_progress_chart.dart';

class ExerciseProgressCard extends StatelessWidget {
  final ExerciseProgress progress;
  final bool useLbs;
  final bool isExpanded;
  final VoidCallback onTap;

  const ExerciseProgressCard({
    super.key,
    required this.progress,
    required this.useLbs,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final category = ExerciseCategory.fromString(progress.exerciseCategory);
    final categoryColor = category.color;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            _buildHeader(context, l10n, categoryColor),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildExpandedContent(context, l10n),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n, Color categoryColor) {
    final metric = _primaryMetric(l10n);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: AppRadius.fullAll,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.exerciseName,
                  style: const TextStyle(fontSize: AppTypo.bodyLg, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.exerciseSessionCount(progress.points.length),
                  style: TextStyle(fontSize: AppTypo.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          if (metric != null) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metric.value,
                  style: TextStyle(
                    fontSize: AppTypo.titleSm,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
                if (metric.change != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metric.changePositive! ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        size: 14,
                        color: metric.changePositive! ? AppColors.success : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        metric.change!,
                        style: TextStyle(
                          fontSize: AppTypo.caption,
                          color: metric.changePositive! ? AppColors.success : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(width: AppSpacing.sm),
          AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.expand_more_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, AppLocalizations l10n) {
    if (progress.points.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
      child: Column(
        children: [
          _buildStatsRow(context, l10n),
          const SizedBox(height: AppSpacing.md),
          _buildChart(context),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n) {
    final widgets = <Widget>[];

    if (progress.isCardio) {
      if (progress.currentMaxDuration != null) {
        widgets.add(_MiniStat(
          label: l10n.isKorean ? '최대 시간' : 'Max Time',
          value: _formatDuration(progress.currentMaxDuration!),
          change: _durationChangeText(),
          changePositive: progress.durationChange != null ? progress.durationChange! > 0 : null,
        ));
      }
      if (progress.currentMaxDistance != null) {
        final unit = useLbs ? 'mi' : 'km';
        final dist = useLbs
            ? (progress.currentMaxDistance! * 0.621371).toStringAsFixed(2)
            : progress.currentMaxDistance!.toStringAsFixed(2);
        widgets.add(_MiniStat(
          label: l10n.isKorean ? '최대 거리' : 'Max Dist',
          value: '$dist$unit',
          change: _distanceChangeText(),
          changePositive: progress.distanceChange != null ? progress.distanceChange! > 0 : null,
        ));
      }
    } else {
      if (progress.hasWeightData && progress.currentMaxWeight != null) {
        final unitLabel = useLbs ? 'lbs' : 'kg';
        final weight = useLbs
            ? (progress.currentMaxWeight! * 2.20462).toStringAsFixed(1)
            : progress.currentMaxWeight!.toStringAsFixed(1);
        widgets.add(_MiniStat(
          label: l10n.maxWeight,
          value: '$weight$unitLabel',
          change: _weightChangeText(),
          changePositive: progress.weightChange != null ? progress.weightChange! > 0 : null,
        ));
      }
      if (progress.hasRepsData && progress.currentMaxReps != null) {
        widgets.add(_MiniStat(
          label: l10n.maxReps,
          value: '${progress.currentMaxReps}',
          change: _repsChangeText(),
          changePositive: progress.repsChange != null ? progress.repsChange! > 0 : null,
        ));
      }
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Row(
      children: widgets.map((w) => Expanded(child: w)).toList(),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (progress.isCardio) {
      return ExerciseProgressChart(
        points: progress.points,
        showWeight: false,
        showReps: false,
        showDuration: true,
        useLbs: useLbs,
        chartColor: ExerciseCategory.fromString(progress.exerciseCategory).color,
      );
    }

    return ExerciseProgressChart(
      points: progress.points,
      showWeight: progress.hasWeightData,
      showReps: progress.hasRepsData && !progress.hasWeightData,
      showDuration: false,
      useLbs: useLbs,
      chartColor: ExerciseCategory.fromString(progress.exerciseCategory).color,
    );
  }

  _MetricInfo? _primaryMetric(AppLocalizations l10n) {
    if (progress.isCardio) {
      if (progress.currentMaxDuration != null) {
        return _MetricInfo(
          value: _formatDuration(progress.currentMaxDuration!),
          change: _durationChangeText(),
          changePositive: progress.durationChange != null ? progress.durationChange! > 0 : null,
        );
      }
    } else if (progress.hasWeightData && progress.currentMaxWeight != null) {
      final unitLabel = useLbs ? 'lbs' : 'kg';
      final weight = useLbs
          ? (progress.currentMaxWeight! * 2.20462).toStringAsFixed(1)
          : progress.currentMaxWeight!.toStringAsFixed(1);
      return _MetricInfo(
        value: '$weight$unitLabel',
        change: _weightChangeText(),
        changePositive: progress.weightChange != null ? progress.weightChange! > 0 : null,
      );
    } else if (progress.hasRepsData && progress.currentMaxReps != null) {
      return _MetricInfo(
        value: '${progress.currentMaxReps} reps',
        change: _repsChangeText(),
        changePositive: progress.repsChange != null ? progress.repsChange! > 0 : null,
      );
    }
    return null;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String? _weightChangeText() {
    if (progress.weightChange == null) return null;
    final unitLabel = useLbs ? 'lbs' : 'kg';
    final change = useLbs
        ? (progress.weightChange! * 2.20462).toStringAsFixed(1)
        : progress.weightChange!.toStringAsFixed(1);
    final sign = progress.weightChange! > 0 ? '+' : '';
    return '$sign$change$unitLabel';
  }

  String? _repsChangeText() {
    if (progress.repsChange == null) return null;
    final sign = progress.repsChange! > 0 ? '+' : '';
    return '$sign${progress.repsChange}';
  }

  String? _durationChangeText() {
    if (progress.durationChange == null) return null;
    final minutes = progress.durationChange! ~/ 60;
    final sign = progress.durationChange! > 0 ? '+' : '';
    return '$sign${minutes}min';
  }

  String? _distanceChangeText() {
    if (progress.distanceChange == null) return null;
    final unit = useLbs ? 'mi' : 'km';
    final change = useLbs
        ? (progress.distanceChange! * 0.621371).toStringAsFixed(2)
        : progress.distanceChange!.toStringAsFixed(2);
    final sign = progress.distanceChange! > 0 ? '+' : '';
    return '$sign$change$unit';
  }
}

class _MetricInfo {
  final String value;
  final String? change;
  final bool? changePositive;

  const _MetricInfo({required this.value, this.change, this.changePositive});
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String? change;
  final bool? changePositive;

  const _MiniStat({
    required this.label,
    required this.value,
    this.change,
    this.changePositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: AppTypo.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: AppTypo.bodyLg, fontWeight: FontWeight.w700),
          ),
          if (change != null)
            Text(
              change!,
              style: TextStyle(
                fontSize: AppTypo.caption,
                color: changePositive == true ? AppColors.success : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
