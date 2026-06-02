import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/exercise_progress.dart';

class ExerciseProgressChart extends StatelessWidget {
  final List<ExerciseProgressPoint> points;
  final bool showWeight;
  final bool showReps;
  final bool showDuration;
  final bool useLbs;
  final Color weightColor;
  final Color repsColor;
  final Color durationColor;

  const ExerciseProgressChart({
    super.key,
    required this.points,
    this.showWeight = true,
    this.showReps = false,
    this.showDuration = false,
    this.useLbs = false,
    this.weightColor = Colors.blue,
    this.repsColor = Colors.green,
    this.durationColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('-')),
      );
    }

    final theme = Theme.of(context);
    final weightData = <FlSpot>[];
    final repsData = <FlSpot>[];
    final durationData = <FlSpot>[];

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (showWeight && point.maxWeight != null && point.maxWeight! > 0) {
        final weight = useLbs ? point.maxWeight! * 2.20462 : point.maxWeight!;
        weightData.add(FlSpot(i.toDouble(), weight));
      }
      if (showReps && point.maxReps != null && point.maxReps! > 0) {
        repsData.add(FlSpot(i.toDouble(), point.maxReps!.toDouble()));
      }
      if (showDuration && point.maxDurationSeconds != null && point.maxDurationSeconds! > 0) {
        durationData.add(FlSpot(i.toDouble(), point.maxDurationSeconds! / 60.0));
      }
    }

    if (weightData.isEmpty && repsData.isEmpty && durationData.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(child: Text('-')),
      );
    }

    final lineBarsData = <LineChartBarData>[];
    double maxY = 0;

    if (showWeight && weightData.isNotEmpty) {
      final maxWeight = weightData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      if (maxWeight > maxY) maxY = maxWeight;
      lineBarsData.add(
        LineChartBarData(
          spots: weightData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: weightColor,
          barWidth: 2,
          dotData: FlDotData(
            show: weightData.length <= 10,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3,
              color: weightColor,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: weightColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    if (showReps && repsData.isNotEmpty) {
      final maxReps = repsData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      if (maxReps > maxY) maxY = maxReps;
      lineBarsData.add(
        LineChartBarData(
          spots: repsData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: repsColor,
          barWidth: 2,
          dotData: FlDotData(
            show: repsData.length <= 10,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3,
              color: repsColor,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: repsColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    if (showDuration && durationData.isNotEmpty) {
      final maxDuration = durationData.map((s) => s.y).reduce((a, b) => a > b ? a : b);
      if (maxDuration > maxY) maxY = maxDuration;
      lineBarsData.add(
        LineChartBarData(
          spots: durationData,
          isCurved: true,
          curveSmoothness: 0.3,
          color: durationColor,
          barWidth: 2,
          dotData: FlDotData(
            show: durationData.length <= 10,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3,
              color: durationColor,
              strokeWidth: 0,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: durationColor.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          lineBarsData: lineBarsData,
          minY: 0,
          maxY: maxY * 1.1,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: points.length <= 7,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < points.length) {
                    final date = points[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(
                          fontSize: 9,
                          color: theme.textTheme.bodySmall?.color,
                        ),
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
            horizontalInterval: maxY > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
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
                    final isWeight = spot.barIndex == 0 && showWeight;
                    final unit = isWeight ? (useLbs ? 'lbs' : 'kg') : 'reps';
                    text = '${spot.y.toStringAsFixed(1)}$unit';
                  }
                  return LineTooltipItem(
                    text,
                    TextStyle(
                      color: spot.bar.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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
