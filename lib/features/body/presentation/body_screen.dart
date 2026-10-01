import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typo.dart';
import '../../settings/data/settings_repository.dart';
import '../data/body_repository.dart';

final bodyRecordsProvider = StreamProvider<List<BodyRecord>>((ref) {
  final repo = ref.watch(bodyRepositoryProvider);
  return repo.watchAllRecords();
});

class BodyScreen extends ConsumerStatefulWidget {
  const BodyScreen({super.key});

  @override
  ConsumerState<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends ConsumerState<BodyScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final recordsAsync = ref.watch(bodyRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.body),
        actions: [
          if (settings.heightCm != null)
            TextButton.icon(
              onPressed: _showHeightDialog,
              icon: const Icon(Icons.height, size: 18, color: Colors.white70),
              label: Text(
                '${settings.displayHeight.toStringAsFixed(settings.useMetric ? 0 : 1)} ${settings.heightUnitLabel}',
                style: const TextStyle(fontSize: AppTypo.bodySm, color: Colors.white70),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightSheet(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addWeight),
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('${l10n.error}: $e')),
        data: (records) => _buildBody(context, records, settings, l10n),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<BodyRecord> records,
    AppSettings settings,
    AppLocalizations l10n,
  ) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.monitor_weight_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.graphPlaceholder,
              style: TextStyle(fontSize: AppTypo.bodyLg, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(bodyRecordsProvider),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (settings.heightCm != null) ...[
            _buildCompactBmi(records.first, settings, l10n),
            const SizedBox(height: AppSpacing.md),
          ],
          _buildWeightSummary(records, settings, l10n),
          const SizedBox(height: AppSpacing.md),
          _buildChart(records, settings, l10n),
          const SizedBox(height: AppSpacing.md),
          _buildRecordsList(records, settings, l10n),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompactBmi(BodyRecord latest, AppSettings settings, AppLocalizations l10n) {
    final bmi = settings.calculateBmi(latest.weightKg);
    if (bmi == null) return const SizedBox.shrink();

    final color = _getBmiColor(bmi);
    final category = _getBmiCategoryLabel(bmi, l10n);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 2.5),
              ),
              child: Center(
                child: Text(
                  bmi.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: AppTypo.titleSm,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'BMI',
                        style: TextStyle(fontSize: AppTypo.bodySm, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: AppRadius.fullAll,
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: AppTypo.caption,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _buildBmiBar(bmi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiBar(double bmi) {
    return ClipRRect(
      borderRadius: AppRadius.fullAll,
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(flex: 35, child: Container(color: Colors.blue)),
                Expanded(flex: 65, child: Container(color: Colors.green)),
                Expanded(flex: 50, child: Container(color: Colors.orange)),
                Expanded(flex: 100, child: Container(color: Colors.red)),
              ],
            ),
            Positioned(
              left: _bmiBarPosition(bmi),
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.fullAll,
                  boxShadow: const [BoxShadow(blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _bmiBarPosition(double bmi) {
    final clamped = bmi.clamp(15.0, 40.0);
    final width = MediaQuery.of(context).size.width - 120;
    return ((clamped - 15) / 25) * width;
  }

  Widget _buildWeightSummary(List<BodyRecord> records, AppSettings settings, AppLocalizations l10n) {
    final latest = records.first;
    final latestWeight = settings.weightUnit == WeightUnit.lbs
        ? latest.weightKg * 2.20462
        : latest.weightKg;
    final unitLabel = settings.weightUnitLabel;

    double? change;
    if (records.length >= 2) {
      final previous = records[1];
      final prevWeight = settings.weightUnit == WeightUnit.lbs
          ? previous.weightKg * 2.20462
          : previous.weightKg;
      change = latestWeight - prevWeight;
    }

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.currentWeight,
                    style: TextStyle(fontSize: AppTypo.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${latestWeight.toStringAsFixed(1)} $unitLabel',
                    style: const TextStyle(fontSize: AppTypo.titleLg, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (change != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.isKorean ? '변화' : 'Change',
                      style: TextStyle(fontSize: AppTypo.caption, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          change > 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 20,
                          color: change > 0 ? Colors.red : AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} $unitLabel',
                          style: TextStyle(
                            fontSize: AppTypo.titleLg,
                            fontWeight: FontWeight.w800,
                            color: change > 0 ? Colors.red : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChart(List<BodyRecord> records, AppSettings settings, AppLocalizations l10n) {
    final chartRecords = records.take(30).toList().reversed.toList();

    if (chartRecords.length < 2) {
      return Card(
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(l10n.graphPlaceholder, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    double minWeight = double.infinity;
    double maxWeight = double.negativeInfinity;

    for (int i = 0; i < chartRecords.length; i++) {
      final record = chartRecords[i];
      final weight = settings.weightUnit == WeightUnit.lbs
          ? record.weightKg * 2.20462
          : record.weightKg;
      spots.add(FlSpot(i.toDouble(), weight));
      if (weight < minWeight) minWeight = weight;
      if (weight > maxWeight) maxWeight = weight;
    }

    final padding = (maxWeight - minWeight) * 0.15;
    if (padding == 0) {
      minWeight -= 1;
      maxWeight += 1;
    } else {
      minWeight -= padding;
      maxWeight += padding;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: Text(l10n.weightTrend, style: AppTypo.subtitle),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxWeight - minWeight) / 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text(
                          value.toStringAsFixed(0),
                          style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: (chartRecords.length / 4).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= chartRecords.length) return const SizedBox();
                          final date = chartRecords[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: (chartRecords.length - 1).toDouble(),
                  minY: minWeight,
                  maxY: maxWeight,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: AppColors.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 3.5,
                          color: AppColors.primary,
                          strokeWidth: 1.5,
                          strokeColor: Theme.of(context).colorScheme.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.2),
                            AppColors.primary.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Theme.of(context).colorScheme.surface,
                      getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                        final unit = settings.weightUnitLabel;
                        return LineTooltipItem(
                          '${spot.y.toStringAsFixed(1)} $unit',
                          TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: AppTypo.bodySm,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(List<BodyRecord> records, AppSettings settings, AppLocalizations l10n) {
    final recentRecords = records.take(15).toList();
    final unitLabel = settings.weightUnitLabel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.recentRecords, style: AppTypo.subtitle),
            const SizedBox(height: AppSpacing.sm),
            ...recentRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              final weight = settings.weightUnit == WeightUnit.lbs
                  ? record.weightKg * 2.20462
                  : record.weightKg;
              final bmi = settings.calculateBmi(record.weightKg);

              double? diff;
              if (index + 1 < records.length) {
                final prevWeight = settings.weightUnit == WeightUnit.lbs
                    ? records[index + 1].weightKg * 2.20462
                    : records[index + 1].weightKg;
                diff = weight - prevWeight;
              }

              return Dismissible(
                key: ValueKey(record.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  color: Colors.red,
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                confirmDismiss: (_) => showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.deleteRecord),
                    content: Text(l10n.deleteRecordConfirm),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: Text(l10n.delete),
                      ),
                    ],
                  ),
                ),
                onDismissed: (_) {
                  ref.read(bodyRepositoryProvider).deleteRecord(record.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.recordDeleted)),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.dateFormat(record.date.year, record.date.month, record.date.day),
                          style: const TextStyle(fontSize: AppTypo.bodyMd),
                        ),
                      ),
                      if (diff != null && diff != 0)
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Text(
                            '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: AppTypo.caption,
                              color: diff > 0 ? Colors.red : AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Text(
                        '${weight.toStringAsFixed(1)} $unitLabel',
                        style: const TextStyle(fontSize: AppTypo.bodyMd, fontWeight: FontWeight.w600),
                      ),
                      if (bmi != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getBmiColor(bmi).withValues(alpha: 0.15),
                            borderRadius: AppRadius.fullAll,
                          ),
                          child: Text(
                            bmi.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: AppTypo.caption,
                              color: _getBmiColor(bmi),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAddWeightSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider);
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    var selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addWeight, style: AppTypo.title),
              const SizedBox(height: AppSpacing.lg),
              if (settings.heightCm == null) ...[
                TextField(
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: l10n.heightLabel(settings.heightUnitLabel),
                    prefixIcon: const Icon(Icons.height),
                    helperText: l10n.heightHelperText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.date,
                    prefixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    l10n.dateFormat(selectedDate.year, selectedDate.month, selectedDate.day),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.weightLabel(settings.weightUnitLabel),
                  prefixIcon: const Icon(Icons.monitor_weight),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () async {
                  final weight = double.tryParse(weightController.text);
                  if (weight == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.enterWeight)),
                    );
                    return;
                  }

                  if (settings.heightCm == null && heightController.text.isNotEmpty) {
                    final height = double.tryParse(heightController.text);
                    if (height != null && height > 0) {
                      final heightCm = settings.heightToCm(height);
                      await ref.read(settingsProvider.notifier).setHeightCm(heightCm);
                    }
                  }

                  final currentSettings = ref.read(settingsProvider);
                  final weightKg = currentSettings.weightUnit == WeightUnit.lbs
                      ? weight * 0.453592
                      : weight;

                  await ref.read(bodyRepositoryProvider).addOrUpdateRecord(
                    date: selectedDate,
                    weightKg: weightKg,
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.weightSaved)),
                    );
                  }
                },
                child: Text(l10n.saveRecord),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHeightDialog() {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController();

    if (settings.heightCm != null) {
      controller.text = settings.displayHeight.toStringAsFixed(1);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.height),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.heightLabel(settings.heightUnitLabel),
            prefixIcon: const Icon(Icons.height),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              final height = double.tryParse(controller.text);
              if (height != null && height > 0) {
                final heightCm = settings.heightToCm(height);
                ref.read(settingsProvider.notifier).setHeightCm(heightCm);
              }
              Navigator.pop(context);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  String _getBmiCategoryLabel(double bmi, AppLocalizations l10n) {
    if (bmi < 18.5) return l10n.bmiUnderweight;
    if (bmi < 25) return l10n.bmiNormal;
    if (bmi < 30) return l10n.bmiOverweight;
    return l10n.bmiObese;
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }
}
