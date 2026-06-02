import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/dashboard_stats.dart';

class WeeklyBarChart extends StatelessWidget {
  final List<DailyVolume> data;
  final bool useLbs;

  const WeeklyBarChart({
    super.key,
    required this.data,
    required this.useLbs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final primaryColor = theme.colorScheme.primary;

    if (data.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.noDataYet,
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
        ),
      );
    }

    final maxVolume = data.map((d) => d.volume).reduce((a, b) => a > b ? a : b);
    final displayMax = maxVolume > 0 ? maxVolume : 1000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.weeklyActivity,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: displayMax * 1.2,
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.surface,
                  tooltipPadding: const EdgeInsets.all(8),
                  tooltipMargin: 8,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final dayData = data[group.x.toInt()];
                    final volume = useLbs
                        ? (dayData.volume * 2.20462).toStringAsFixed(0)
                        : dayData.volume.toStringAsFixed(0);
                    final unit = useLbs ? 'lbs' : 'kg';
                    return BarTooltipItem(
                      '$volume$unit\n${dayData.setCount} sets',
                      TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        final date = data[index].date;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                l10n.dayAbbr(date.weekday),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                              Text(
                                '${date.month}/${date.day}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    reservedSize: 40,
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: displayMax / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final index = entry.key;
                final dayData = entry.value;
                final isToday = index == data.length - 1;

                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: dayData.volume > 0 ? dayData.volume : 0,
                      color: isToday
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.5),
                      width: 24,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
