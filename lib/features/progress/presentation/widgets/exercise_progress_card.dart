import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/exercise_progress.dart';
import 'exercise_progress_chart.dart';

class ExerciseProgressCard extends StatelessWidget {
  final ExerciseProgress progress;
  final bool useLbs;

  const ExerciseProgressCard({
    super.key,
    required this.progress,
    required this.useLbs,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final unitLabel = useLbs ? 'lbs' : 'kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              progress.exerciseName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatsRow(context, l10n, unitLabel),
            const SizedBox(height: 12),
            _buildChart(context, theme),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildStatsRow(BuildContext context, AppLocalizations l10n, String unitLabel) {
    final widgets = <Widget>[];

    if (progress.isCardio) {
      // Cardio exercise - show duration and distance
      if (progress.currentMaxDuration != null) {
        String? changeText;
        Color? changeColor;
        if (progress.durationChange != null) {
          final changeMinutes = progress.durationChange! ~/ 60;
          final sign = progress.durationChange! > 0 ? '+' : '';
          changeText = '$sign${changeMinutes}min';
          changeColor = progress.durationChange! > 0 ? Colors.green : Colors.red;
        }

        widgets.add(
          _StatItem(
            label: l10n.isKorean ? '최대 시간' : 'Max Time',
            value: _formatDuration(progress.currentMaxDuration!),
            changeText: changeText,
            changeColor: changeColor,
            color: Colors.orange,
          ),
        );
      }

      if (progress.currentMaxDistance != null) {
        final distanceUnit = useLbs ? 'mi' : 'km';
        final displayDistance = useLbs
            ? (progress.currentMaxDistance! * 0.621371).toStringAsFixed(2)
            : progress.currentMaxDistance!.toStringAsFixed(2);

        String? changeText;
        Color? changeColor;
        if (progress.distanceChange != null) {
          final displayChange = useLbs
              ? (progress.distanceChange! * 0.621371).toStringAsFixed(2)
              : progress.distanceChange!.toStringAsFixed(2);
          final sign = progress.distanceChange! > 0 ? '+' : '';
          changeText = '$sign$displayChange$distanceUnit';
          changeColor = progress.distanceChange! > 0 ? Colors.green : Colors.red;
        }

        widgets.add(
          _StatItem(
            label: l10n.isKorean ? '최대 거리' : 'Max Distance',
            value: '$displayDistance$distanceUnit',
            changeText: changeText,
            changeColor: changeColor,
            color: Colors.purple,
          ),
        );
      }
    } else {
      // Strength exercise - show weight and reps
      if (progress.hasWeightData && progress.currentMaxWeight != null) {
        final displayWeight = useLbs
            ? (progress.currentMaxWeight! * 2.20462).toStringAsFixed(1)
            : progress.currentMaxWeight!.toStringAsFixed(1);

        String? changeText;
        Color? changeColor;
        if (progress.weightChange != null) {
          final displayChange = useLbs
              ? (progress.weightChange! * 2.20462).toStringAsFixed(1)
              : progress.weightChange!.toStringAsFixed(1);
          final sign = progress.weightChange! > 0 ? '+' : '';
          changeText = '$sign$displayChange$unitLabel';
          changeColor = progress.weightChange! > 0 ? Colors.green : Colors.red;
        }

        widgets.add(
          _StatItem(
            label: l10n.maxWeight,
            value: '$displayWeight$unitLabel',
            changeText: changeText,
            changeColor: changeColor,
            color: Colors.blue,
          ),
        );
      }

      if (progress.hasRepsData && progress.currentMaxReps != null) {
        String? changeText;
        Color? changeColor;
        if (progress.repsChange != null) {
          final sign = progress.repsChange! > 0 ? '+' : '';
          changeText = '$sign${progress.repsChange}';
          changeColor = progress.repsChange! > 0 ? Colors.green : Colors.red;
        }

        widgets.add(
          _StatItem(
            label: l10n.maxReps,
            value: '${progress.currentMaxReps}',
            changeText: changeText,
            changeColor: changeColor,
            color: Colors.green,
          ),
        );
      }
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: widgets.expand((w) => [Expanded(child: w)]).toList(),
    );
  }

  Widget _buildChart(BuildContext context, ThemeData theme) {
    if (progress.points.isEmpty) {
      return const SizedBox.shrink();
    }

    if (progress.isCardio) {
      return ExerciseProgressChart(
        points: progress.points,
        showWeight: false,
        showReps: false,
        showDuration: true,
        useLbs: useLbs,
        weightColor: Colors.blue,
        repsColor: Colors.green,
        durationColor: Colors.orange,
      );
    }

    final showWeight = progress.hasWeightData;
    final showReps = progress.hasRepsData && !showWeight;

    return ExerciseProgressChart(
      points: progress.points,
      showWeight: showWeight,
      showReps: showReps,
      showDuration: false,
      useLbs: useLbs,
      weightColor: Colors.blue,
      repsColor: Colors.green,
      durationColor: Colors.orange,
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String? changeText;
  final Color? changeColor;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    this.changeText,
    this.changeColor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (changeText != null) ...[
              const SizedBox(width: 8),
              Text(
                changeText!,
                style: TextStyle(
                  fontSize: 12,
                  color: changeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
