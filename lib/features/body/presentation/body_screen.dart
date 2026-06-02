import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
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
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    final l10n = AppLocalizations.of(context);
    final settings = ref.read(settingsProvider);

    if (_weightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterWeight)),
      );
      return;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterWeight)),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    if (settings.heightCm == null && _heightController.text.isNotEmpty) {
      final height = double.tryParse(_heightController.text);
      if (height != null && height > 0) {
        final heightCm = settings.heightToCm(height);
        await ref.read(settingsProvider.notifier).setHeightCm(heightCm);
      }
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(bodyRepositoryProvider);
      final currentSettings = ref.read(settingsProvider);

      final weightKg = currentSettings.weightUnit == WeightUnit.lbs
          ? weight * 0.453592
          : weight;

      await repo.addOrUpdateRecord(
        date: _selectedDate,
        weightKg: weightKg,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.weightSaved)),
        );
        _weightController.clear();
        setState(() {
          _selectedDate = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.heightLabel(settings.heightUnitLabel),
                prefixIcon: const Icon(Icons.height),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final unitLabel = settings.weightUnitLabel;
    final heightUnitLabel = settings.heightUnitLabel;
    final recordsAsync = ref.watch(bodyRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.body),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (settings.heightCm != null)
              _buildBmiCard(settings, recordsAsync, l10n),
            if (settings.heightCm != null) const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weightRecord,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (settings.heightCm == null) ...[
                      TextField(
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.heightLabel(heightUnitLabel),
                          prefixIcon: const Icon(Icons.height),
                          helperText: l10n.heightHelperText,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.date,
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          l10n.dateFormat(_selectedDate.year, _selectedDate.month, _selectedDate.day),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l10n.weightLabel(unitLabel),
                        prefixIcon: const Icon(Icons.monitor_weight),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveRecord,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.saveRecord),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.weightTrend,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (settings.heightCm != null)
                          TextButton.icon(
                            onPressed: _showHeightDialog,
                            icon: const Icon(Icons.height, size: 18),
                            label: Text(
                              '${settings.displayHeight.toStringAsFixed(settings.useMetric ? 0 : 1)} ${settings.heightUnitLabel}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    recordsAsync.when(
                      loading: () => const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => SizedBox(
                        height: 200,
                        child: Center(child: Text('${l10n.error}: $e')),
                      ),
                      data: (records) => _buildChart(records, settings),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            recordsAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (records) => _buildRecordsList(records, settings, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBmiCard(AppSettings settings, AsyncValue<List<BodyRecord>> recordsAsync, AppLocalizations l10n) {
    return recordsAsync.when(
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
      data: (records) {
        if (records.isEmpty) return const SizedBox();

        final latestRecord = records.first;
        final bmi = settings.calculateBmi(latestRecord.weightKg);
        if (bmi == null) return const SizedBox();

        final category = settings.getBmiCategory(bmi, l10n.isKorean);
        final color = _getBmiColor(bmi);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.bmiTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.2),
                        border: Border.all(color: color, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          bmi.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.bmiDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBmiScale(bmi),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBmiScale(double bmi) {
    return Column(
      children: [
        SizedBox(
          height: 8,
          child: Row(
            children: [
              Expanded(flex: 185, child: Container(color: Colors.blue)),
              Expanded(flex: 65, child: Container(color: Colors.green)),
              Expanded(flex: 50, child: Container(color: Colors.orange)),
              Expanded(flex: 100, child: Container(color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('15', style: TextStyle(fontSize: 10)),
                Text('18.5', style: TextStyle(fontSize: 10)),
                Text('25', style: TextStyle(fontSize: 10)),
                Text('30', style: TextStyle(fontSize: 10)),
                Text('40', style: TextStyle(fontSize: 10)),
              ],
            ),
            Positioned(
              left: _calculateBmiPosition(bmi),
              top: -12,
              child: const Icon(Icons.arrow_drop_down, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateBmiPosition(double bmi) {
    final clampedBmi = bmi.clamp(15.0, 40.0);
    final percentage = (clampedBmi - 15) / 25;
    final screenWidth = MediaQuery.of(context).size.width - 80;
    return (percentage * screenWidth) - 10;
  }

  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildChart(List<BodyRecord> records, AppSettings settings) {
    if (records.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.graphPlaceholder,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final chartRecords = records.take(30).toList().reversed.toList();

    if (chartRecords.length < 2) {
      final l10n = AppLocalizations.of(context);
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.graphPlaceholder,
            style: const TextStyle(color: Colors.grey),
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

    final padding = (maxWeight - minWeight) * 0.1;
    if (padding == 0) {
      minWeight -= 1;
      maxWeight += 1;
    } else {
      minWeight -= padding;
      maxWeight += padding;
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxWeight - minWeight) / 4,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (chartRecords.length / 4).ceilToDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= chartRecords.length) {
                    return const SizedBox();
                  }
                  final date = chartRecords[index].date;
                  return Text(
                    '${date.month}/${date.day}',
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
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
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordsList(List<BodyRecord> records, AppSettings settings, AppLocalizations l10n) {
    if (records.isEmpty) return const SizedBox();

    final recentRecords = records.take(10).toList();
    final unitLabel = settings.weightUnitLabel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.recentRecords,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...recentRecords.map((record) {
              final weight = settings.weightUnit == WeightUnit.lbs
                  ? record.weightKg * 2.20462
                  : record.weightKg;
              final bmi = settings.calculateBmi(record.weightKg);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.dateFormat(record.date.year, record.date.month, record.date.day),
                      style: const TextStyle(fontSize: 14),
                    ),
                    Row(
                      children: [
                        Text(
                          '${weight.toStringAsFixed(1)} $unitLabel',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (bmi != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getBmiColor(bmi).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'BMI ${bmi.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getBmiColor(bmi),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
