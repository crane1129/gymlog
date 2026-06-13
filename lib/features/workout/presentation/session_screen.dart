import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/constants/exercise_type.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../exercise/data/exercise_repository.dart';
import '../../exercise/presentation/exercise_picker_screen.dart';
import '../../settings/data/settings_repository.dart';
import '../data/workout_repository.dart';

class SetData {
  final String? existingId;
  final TextEditingController weightController;
  final TextEditingController repsController;

  SetData()
      : existingId = null,
        weightController = TextEditingController(),
        repsController = TextEditingController();

  SetData.fromExisting({
    required this.existingId,
    required double? weightKgValue,
    required int? repsValue,
  })  : weightController = TextEditingController(
          text: weightKgValue != null
              ? (weightKgValue % 1 == 0
                  ? weightKgValue.toInt().toString()
                  : weightKgValue.toStringAsFixed(1))
              : '',
        ),
        repsController = TextEditingController(
          text: repsValue != null ? repsValue.toString() : '',
        );

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
  final String? existingId;
  final TextEditingController durationController;
  final TextEditingController distanceController;

  CardioSetData()
      : existingId = null,
        durationController = TextEditingController(),
        distanceController = TextEditingController();

  CardioSetData.fromExisting({
    required this.existingId,
    required int? durationSecondsValue,
    required double? distanceKmValue,
  })  : durationController = TextEditingController(
          text: durationSecondsValue != null
              ? (durationSecondsValue / 60).toStringAsFixed(0)
              : '',
        ),
        distanceController = TextEditingController(
          text: distanceKmValue != null
              ? (distanceKmValue % 1 == 0
                  ? distanceKmValue.toInt().toString()
                  : distanceKmValue.toStringAsFixed(2))
              : '',
        );

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

  ExerciseEntry.fromExistingSets({
    required this.exerciseId,
    required this.exerciseName,
    required this.exerciseType,
    required List<SetData> initialSets,
    required List<CardioSetData> initialCardioSets,
  })  : sets = initialSets,
        cardioSets = initialCardioSets;

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

  /// Edit mode: 히스토리에서 특정 운동 세트를 편집할 때 사용
  final DateTime? initialDate;

  /// Edit mode: 히스토리에서 특정 운동 세트를 편집할 때 사용
  final String? editExerciseId;
  final String? editExerciseName;
  final String? editExerciseType;
  final List<WorkoutSet>? editExistingSets;

  const SessionScreen({
    super.key,
    required this.sessionId,
    this.initialDate,
    this.editExerciseId,
    this.editExerciseName,
    this.editExerciseType,
    this.editExistingSets,
  });

  bool get isEditMode => editExerciseId != null;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  final List<ExerciseEntry> _exercises = [];
  final Set<String> _preloadedExerciseIds = {};
  DateTime _sessionDate = DateTime.now();
  final DateTime _startTime = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _sessionDate = widget.initialDate!;
    }
    if (widget.isEditMode) {
      _initEditMode();
    } else if (widget.initialDate == null) {
      _loadTodaysExercises();
    }
  }

  Future<void> _loadTodaysExercises() async {
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    final settings = ref.read(settingsProvider);
    final useLbs = settings.weightUnit == WeightUnit.lbs;
    final isKorean = settings.locale.languageCode == 'ko';

    final session = await workoutRepo.getSessionByDate(_sessionDate);
    if (session == null) return;

    final sets = await workoutRepo.getSetsBySession(session.id);
    if (sets.isEmpty) return;

    final groupedSets = <String, List<WorkoutSet>>{};
    for (final set in sets) {
      groupedSets.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    final entries = <ExerciseEntry>[];
    for (final entry in groupedSets.entries) {
      final exerciseId = entry.key;
      final exerciseSets = entry.value;

      final exercise = await exerciseRepo.getExerciseById(exerciseId);
      if (exercise == null) continue;

      String exerciseName;
      try {
        final defaultEx = defaultExercises.firstWhere((e) => e.id == exerciseId);
        exerciseName = defaultEx.getName(isKorean);
      } catch (_) {
        exerciseName = exercise.name;
      }

      final exerciseType = ExerciseTypeExtension.fromString(
        exercise.exerciseType ?? 'strength',
      );

      if (exerciseType == ExerciseType.cardio) {
        final cardioSets = exerciseSets
            .map((s) => CardioSetData.fromExisting(
                  existingId: s.id,
                  durationSecondsValue: s.durationSeconds,
                  distanceKmValue: s.distanceKm != null
                      ? (useLbs ? s.distanceKm! / 1.60934 : s.distanceKm)
                      : null,
                ))
            .toList();
        cardioSets.add(CardioSetData());
        entries.add(ExerciseEntry.fromExistingSets(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          exerciseType: exerciseType,
          initialSets: [],
          initialCardioSets: cardioSets,
        ));
      } else {
        final strengthSets = exerciseSets
            .map((s) => SetData.fromExisting(
                  existingId: s.id,
                  weightKgValue: s.weightKg != null
                      ? (useLbs ? s.weightKg! * 2.20462 : s.weightKg)
                      : null,
                  repsValue: s.reps,
                ))
            .toList();
        strengthSets.add(SetData());
        entries.add(ExerciseEntry.fromExistingSets(
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          exerciseType: exerciseType,
          initialSets: strengthSets,
          initialCardioSets: [],
        ));
      }

      _preloadedExerciseIds.add(exerciseId);
    }

    if (mounted && entries.isNotEmpty) {
      setState(() {
        _exercises.addAll(entries);
      });
    }
  }

  void _initEditMode() {
    final existingSets = widget.editExistingSets ?? [];
    final exerciseType = ExerciseTypeExtension.fromString(
      widget.editExerciseType ?? 'strength',
    );
    final settings = ref.read(settingsProvider);
    final useLbs = settings.weightUnit == WeightUnit.lbs;

    if (exerciseType == ExerciseType.cardio) {
      final cardioSets = existingSets
          .map((s) => CardioSetData.fromExisting(
                existingId: s.id,
                durationSecondsValue: s.durationSeconds,
                // DB는 항상 km 저장 → lbs 단위(mi)면 역변환
                distanceKmValue: s.distanceKm != null
                    ? (useLbs ? s.distanceKm! / 1.60934 : s.distanceKm)
                    : null,
              ))
          .toList();
      cardioSets.add(CardioSetData());
      _exercises.add(ExerciseEntry.fromExistingSets(
        exerciseId: widget.editExerciseId!,
        exerciseName: widget.editExerciseName!,
        exerciseType: exerciseType,
        initialSets: [],
        initialCardioSets: cardioSets,
      ));
    } else {
      final sets = existingSets
          .map((s) => SetData.fromExisting(
                existingId: s.id,
                // DB는 항상 kg 저장 → lbs 단위면 역변환
                weightKgValue: s.weightKg != null
                    ? (useLbs ? s.weightKg! * 2.20462 : s.weightKg)
                    : null,
                repsValue: s.reps,
              ))
          .toList();
      sets.add(SetData());
      _exercises.add(ExerciseEntry.fromExistingSets(
        exerciseId: widget.editExerciseId!,
        exerciseName: widget.editExerciseName!,
        exerciseType: exerciseType,
        initialSets: sets,
        initialCardioSets: [],
      ));
    }
  }

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
    const uuid = Uuid();
    final now = DateTime.now();

    final sessionId = await repo.getOrCreateSession(_sessionDate);
    final existingSets = await repo.getSetsBySession(sessionId);

    for (final exercise in _exercises) {
      if (_preloadedExerciseIds.contains(exercise.exerciseId)) {
        if (exercise.isCardio) {
          final validSets = exercise.validCardioSets;
          final companions = <WorkoutSetsCompanion>[];
          for (int i = 0; i < validSets.length; i++) {
            final setData = validSets[i];
            final inputDistance = setData.distanceKm ?? 0;
            final distanceKm = settings.useLbs
                ? inputDistance * 1.60934
                : inputDistance;
            companions.add(WorkoutSetsCompanion.insert(
              id: setData.existingId ?? uuid.v4(),
              sessionId: sessionId,
              exerciseId: exercise.exerciseId,
              setNumber: i + 1,
              durationSeconds: Value(setData.durationSeconds),
              distanceKm: Value(distanceKm),
              createdAt: now,
              updatedAt: now,
            ));
          }
          await repo.replaceExerciseSets(
            sessionId: sessionId,
            exerciseId: exercise.exerciseId,
            newSets: companions,
          );
        } else {
          final validSets = exercise.validSets;
          final companions = <WorkoutSetsCompanion>[];
          for (int i = 0; i < validSets.length; i++) {
            final setData = validSets[i];
            final inputWeight = setData.weightKg ?? 0;
            final weightKg = settings.weightUnit == WeightUnit.lbs
                ? inputWeight * 0.453592
                : inputWeight;
            companions.add(WorkoutSetsCompanion.insert(
              id: setData.existingId ?? uuid.v4(),
              sessionId: sessionId,
              exerciseId: exercise.exerciseId,
              setNumber: i + 1,
              reps: Value(setData.reps ?? 0),
              weightKg: Value(weightKg),
              createdAt: now,
              updatedAt: now,
            ));
          }
          await repo.replaceExerciseSets(
            sessionId: sessionId,
            exerciseId: exercise.exerciseId,
            newSets: companions,
          );
        }
      } else {
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
    }

    await repo.updateSession(
      sessionId,
      durationMinutes: durationMinutes,
    );
  }

  Future<void> _saveEditSession() async {
    final repo = ref.read(workoutRepositoryProvider);
    final settings = ref.read(settingsProvider);
    const uuid = Uuid();
    final now = DateTime.now();

    for (final exercise in _exercises) {
      if (exercise.isCardio) {
        final validSets = exercise.validCardioSets;
        final companions = <WorkoutSetsCompanion>[];
        for (int i = 0; i < validSets.length; i++) {
          final setData = validSets[i];
          final inputDistance = setData.distanceKm ?? 0;
          final distanceKm = settings.useLbs
              ? inputDistance * 1.60934
              : inputDistance;
          companions.add(WorkoutSetsCompanion.insert(
            id: setData.existingId ?? uuid.v4(),
            sessionId: widget.sessionId,
            exerciseId: exercise.exerciseId,
            setNumber: i + 1,
            durationSeconds: Value(setData.durationSeconds),
            distanceKm: Value(distanceKm),
            createdAt: now,
            updatedAt: now,
          ));
        }
        await repo.replaceExerciseSets(
          sessionId: widget.sessionId,
          exerciseId: exercise.exerciseId,
          newSets: companions,
        );
      } else {
        final validSets = exercise.validSets;
        final companions = <WorkoutSetsCompanion>[];
        for (int i = 0; i < validSets.length; i++) {
          final setData = validSets[i];
          final inputWeight = setData.weightKg ?? 0;
          final weightKg = settings.weightUnit == WeightUnit.lbs
              ? inputWeight * 0.453592
              : inputWeight;
          companions.add(WorkoutSetsCompanion.insert(
            id: setData.existingId ?? uuid.v4(),
            sessionId: widget.sessionId,
            exerciseId: exercise.exerciseId,
            setNumber: i + 1,
            reps: Value(setData.reps ?? 0),
            weightKg: Value(weightKg),
            createdAt: now,
            updatedAt: now,
          ));
        }
        await repo.replaceExerciseSets(
          sessionId: widget.sessionId,
          exerciseId: exercise.exerciseId,
          newSets: companions,
        );
      }
    }
  }

  int get _totalSets {
    int count = 0;
    for (final exercise in _exercises) {
      count += exercise.totalValidSets;
    }
    return count;
  }

  void _finishSession() {
    if (widget.isEditMode) {
      _saveEdit();
    } else {
      _confirmFinish();
    }
  }

  void _saveEdit() {
    final l10n = AppLocalizations.of(context);
    final totalSets = _totalSets;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (totalSets == 0) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(l10n.noSetsRecorded)),
      );
      return;
    }

    setState(() => _isSaving = true);
    _saveEditSession().then((_) {
      if (mounted) {
        setState(() => _isSaving = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.saveChangesDone)),
        );
        Navigator.of(context).pop(true);
      }
    }).catchError((e) {
      if (mounted) {
        setState(() => _isSaving = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.saveFailed(e.toString()))),
        );
      }
    });
  }

  void _confirmFinish() {
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
        title: widget.isEditMode
            ? Text(l10n.editSets)
            : InkWell(
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
          if (!widget.isEditMode)
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
              child: Text(
                widget.isEditMode ? l10n.saveChanges : l10n.finish,
                style: const TextStyle(color: Colors.white),
              ),
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
