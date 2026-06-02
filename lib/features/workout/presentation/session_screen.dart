import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/exercise_type.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../exercise/presentation/exercise_picker_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../data/workout_repository.dart';

class SetData {
  final TextEditingController weightController;
  final TextEditingController repsController;

  SetData()
      : weightController = TextEditingController(),
        repsController = TextEditingController();

  bool get isEmpty =>
      weightController.text.isEmpty && repsController.text.isEmpty;

  bool get isComplete =>
      weightController.text.isNotEmpty || repsController.text.isNotEmpty;

  double? get weightKg {
    final text = weightController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  int? get reps {
    final text = repsController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  bool get isValid => weightKg != null || reps != null;

  void dispose() {
    weightController.dispose();
    repsController.dispose();
  }
}

class CardioSetData {
  final TextEditingController durationController;
  final TextEditingController distanceController;

  CardioSetData()
      : durationController = TextEditingController(),
        distanceController = TextEditingController();

  bool get isEmpty =>
      durationController.text.isEmpty && distanceController.text.isEmpty;

  bool get isComplete =>
      durationController.text.isNotEmpty || distanceController.text.isNotEmpty;

  int? get durationSeconds {
    final text = durationController.text.trim();
    if (text.isEmpty) return null;
    final minutes = double.tryParse(text);
    return minutes != null ? (minutes * 60).round() : null;
  }

  double? get distanceKm {
    final text = distanceController.text.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get isValid => durationSeconds != null || distanceKm != null;

  void dispose() {
    durationController.dispose();
    distanceController.dispose();
  }
}

class ExerciseEntry {
  final String exerciseId;
  final String exerciseName;
  final ExerciseType exerciseType;
  final List<SetData> sets;
  final List<CardioSetData> cardioSets;

  ExerciseEntry({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
  })  : sets = exerciseType == ExerciseType.strength ? [SetData()] : [],
        cardioSets = exerciseType == ExerciseType.cardio ? [CardioSetData()] : [];

  bool get isCardio => exerciseType == ExerciseType.cardio;

  List<SetData> get validSets => sets.where((s) => s.isValid).toList();
  List<CardioSetData> get validCardioSets => cardioSets.where((s) => s.isValid).toList();

  int get totalValidSets => isCardio ? validCardioSets.length : validSets.length;

  void dispose() {
    for (final set in sets) {
      set.dispose();
    }
    for (final set in cardioSets) {
      set.dispose();
    }
  }
}

class SessionScreen extends ConsumerStatefulWidget {
  final String sessionId;

  const SessionScreen({super.key, required this.sessionId});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final List<ExerciseEntry> _exercises = [];
  DateTime _sessionDate = DateTime.now();
  final DateTime _startTime = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    for (final exercise in _exercises) {
      exercise.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sessionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _sessionDate) {
      setState(() {
        _sessionDate = picked;
      });
    }
  }

  void _addExercise() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const ExercisePickerScreen(),
    );

    if (result != null && mounted) {
      final exerciseTypeStr = result['exerciseType'] as String? ?? 'strength';
      final exerciseType = ExerciseTypeExtension.fromString(exerciseTypeStr);

      setState(() {
        _exercises.insert(0, ExerciseEntry(
          exerciseId: result['id'] as String,
          exerciseName: result['name'] as String,
          exerciseType: exerciseType,
        ));
      });
    }
  }

  void _onSetChanged(ExerciseEntry exercise, int setIndex) {
    setState(() {
      final lastSet = exercise.sets.last;
      if (lastSet.isComplete && setIndex == exercise.sets.length - 1) {
        exercise.sets.add(SetData());
      }
    });
  }

  void _onCardioSetChanged(ExerciseEntry exercise, int setIndex) {
    setState(() {
      final lastSet = exercise.cardioSets.last;
      if (lastSet.isComplete && setIndex == exercise.cardioSets.length - 1) {
        exercise.cardioSets.add(CardioSetData());
      }
    });
  }

  void _removeSet(ExerciseEntry exercise, int setIndex) {
    if (exercise.sets.length > 1) {
      setState(() {
        exercise.sets[setIndex].dispose();
        exercise.sets.removeAt(setIndex);
      });
    }
  }

  void _removeCardioSet(ExerciseEntry exercise, int setIndex) {
    if (exercise.cardioSets.length > 1) {
      setState(() {
        exercise.cardioSets[setIndex].dispose();
        exercise.cardioSets.removeAt(setIndex);
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises[index].dispose();
      _exercises.removeAt(index);
    });
  }

  Future<void> _saveSession() async {
    final repo = ref.read(workoutRepositoryProvider);
    final settings = ref.read(settingsProvider);
    final durationMinutes = DateTime.now().difference(_startTime).inMinutes;

    final sessionId = await repo.getOrCreateSession(_sessionDate);
    final existingSets = await repo.getSetsBySession(sessionId);

    for (final exercise in _exercises) {
      final existingExerciseSets = existingSets
          .where((s) => s.exerciseId == exercise.exerciseId)
          .length;

      if (exercise.isCardio) {
        final validSets = exercise.validCardioSets;
        for (int i = 0; i < validSets.length; i++) {
          final setData = validSets[i];
          final inputDistance = setData.distanceKm ?? 0;
          final distanceKm = settings.useLbs
              ? inputDistance * 1.60934
              : inputDistance;

          await repo.addSet(
            sessionId: sessionId,
            exerciseId: exercise.exerciseId,
            setNumber: existingExerciseSets + i + 1,
            durationSeconds: setData.durationSeconds,
            distanceKm: distanceKm,
          );
        }
      } else {
        final validSets = exercise.validSets;
        for (int i = 0; i < validSets.length; i++) {
          final setData = validSets[i];
          final inputWeight = setData.weightKg ?? 0;
          final weightKg = settings.weightUnit == WeightUnit.lbs
              ? inputWeight * 0.453592
              : inputWeight;

          await repo.addSet(
            sessionId: sessionId,
            exerciseId: exercise.exerciseId,
            setNumber: existingExerciseSets + i + 1,
            reps: setData.reps ?? 0,
            weightKg: weightKg,
          );
        }
      }
    }

    await repo.updateSession(
      sessionId,
      durationMinutes: durationMinutes,
    );
  }

  int get _totalSets {
    int count = 0;
    for (final exercise in _exercises) {
      count += exercise.totalValidSets;
    }
    return count;
  }

  void _finishSession() {
    final l10n = AppLocalizations.of(context);
    final totalSets = _totalSets;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.finishWorkout),
        content: Text(
          totalSets > 0
              ? l10n.finishWorkoutMessage(_exercises.length, totalSets)
              : l10n.noSetsRecorded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (totalSets > 0) {
                setState(() => _isSaving = true);
                try {
                  await _saveSession();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.setsSaved(totalSets))),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text(l10n.saveFailed(e.toString()))),
                  );
                } finally {
                  if (mounted) {
                    setState(() => _isSaving = false);
                  }
                }
              }
              router.go('/');
            },
            child: Text(l10n.finish),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _selectDate,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.workoutDateTitle(_sessionDate.month, _sessionDate.day)),
                const SizedBox(width: 4),
                const Icon(Icons.calendar_today, size: 18),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _addExercise,
            icon: const Icon(Icons.add),
            tooltip: l10n.addExercise,
          ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _finishSession,
              child: Text(l10n.finish, style: const TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _exercises.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.addExercisePrompt,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addExercise),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                if (exercise.isCardio) {
                  return _buildCardioExerciseCard(exercise, index);
                }
                return _buildExerciseCard(exercise, index);
              },
            ),
    );
  }

  Widget _buildExerciseCard(ExerciseEntry exercise, int exerciseIndex) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final unitLabel = settings.weightUnit == WeightUnit.kg ? 'kg' : 'lbs';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeExercise(exerciseIndex),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 40, child: Text(l10n.set, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(unitLabel, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.reps, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 8),
            ...exercise.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final setData = entry.value;
              return _buildSetRow(exercise, setIndex, setData);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCardioExerciseCard(ExerciseEntry exercise, int exerciseIndex) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final distanceUnit = settings.useLbs ? 'mi' : 'km';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_run, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exercise.exerciseName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _removeExercise(exerciseIndex),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(width: 40, child: Text(l10n.set, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.durationMin, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Text(distanceUnit, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 8),
            ...exercise.cardioSets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              final setData = entry.value;
              return _buildCardioSetRow(exercise, setIndex, setData);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(ExerciseEntry exercise, int setIndex, SetData setData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${setIndex + 1}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: setData.weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onChanged: (_) => _onSetChanged(exercise, setIndex),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: setData.repsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onChanged: (_) => _onSetChanged(exercise, setIndex),
            ),
          ),
          SizedBox(
            width: 40,
            child: setIndex < exercise.sets.length - 1 || exercise.sets.length > 1
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => _removeSet(exercise, setIndex),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCardioSetRow(ExerciseEntry exercise, int setIndex, CardioSetData setData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${setIndex + 1}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: setData.durationController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onChanged: (_) => _onCardioSetChanged(exercise, setIndex),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: setData.distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              onChanged: (_) => _onCardioSetChanged(exercise, setIndex),
            ),
          ),
          SizedBox(
            width: 40,
            child: setIndex < exercise.cardioSets.length - 1 || exercise.cardioSets.length > 1
                ? IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => _removeCardioSet(exercise, setIndex),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
