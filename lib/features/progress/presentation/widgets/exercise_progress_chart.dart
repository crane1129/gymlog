import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_typo.dart';
import '../../domain/exercise_progress.dart';

class ExerciseProgressChart extends StatelessWidget {
  final List<ExerciseProgressPoint> points;
  final bool showWeight;
  final bool showReps;
  final bool showDuration;
  final bool useLbs;
  final Color chartColor;

  const ExerciseProgressChart({
    super.key,
    required this.points,
    this.showWeight = true,
    this.showReps = false,
    this.showDuration = false,
    this.useLbs = false,
    this.chartColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('-')));
    }

    final theme = Theme.of(context);
    final data = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      double? value;

      if (showWeight && point.maxWeight != null && point.maxWeight! > 0) {
        value = useLbs ? point.maxWeight! * 2.20462 : point.maxWeight!;
      } else if (showReps && point.maxReps != null && point.maxReps! > 0) {
        value = point.maxReps!.toDouble();
      } else if (showDuration && point.maxDurationSeconds != null && point.maxDurationSeconds! > 0) {
        value = point.maxDurationSeconds! / 60.0;
      }

      if (value != null) {
        data.add(FlSpot(i.toDouble(), value));
      }
    }

    if (data.isEmpty) {
      return const SizedBox(height: 180, child: Center(child: Text('-')));
    }

    final maxY = data.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = data.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final range = maxY - minY;
    final adjustedMinY = range > 0 ? minY - range * 0.1 : minY - 1;
    final adjustedMaxY = maxY + (range > 0 ? range * 0.1 : 1);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data,
              isCurved: true,
              curveSmoothness: 0.3,
              color: chartColor,
              barWidth: 2.5,
              dotData: FlDotData(
                show: data.length <= 12,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 3,
                  color: chartColor,
                  strokeWidth: 1.5,
                  strokeColor: theme.colorScheme.surface,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    chartColor.withValues(alpha: 0.2),
                    chartColor.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
          minY: adjustedMinY.clamp(0, double.infinity),
          maxY: adjustedMaxY,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: points.length <= 8,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < points.length) {
                    final date = points[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(fontSize: 9, color: theme.textTheme.bodySmall?.color),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                reservedSize: 20,
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? (adjustedMaxY - adjustedMinY.clamp(0, double.infinity)) / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.2),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => theme.colorScheme.surface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  String text;
                  if (showDuration) {
                    final minutes = spot.y.toInt();
                    final seconds = ((spot.y - minutes) * 60).toInt();
                    text = '$minutes:${seconds.toString().padLeft(2, '0')}';
                  } else {
                    final unit = showWeight ? (useLbs ? 'lbs' : 'kg') : 'reps';
                    text = '${spot.y.toStringAsFixed(1)}$unit';
                  }
                  return LineTooltipItem(
                    text,
                    TextStyle(
                      color: chartColor,
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypo.bodySm,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
