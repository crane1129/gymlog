import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/theme/app_radius.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typo.dart';
import '../data/workout_repository.dart';
import '../../exercise/data/exercise_repository.dart';
import '../../settings/data/settings_repository.dart';
import 'session_screen.dart';

final sessionsProvider = StreamProvider<List<WorkoutSession>>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.watchAllSessions();
});

final sessionsWithSetsProvider = FutureProvider<Set<String>>((ref) async {
  // Watch sessionsProvider to trigger refresh when sessions change
  final sessionsAsync = ref.watch(sessionsProvider);
  final sessions = sessionsAsync.valueOrNull ?? [];

  if (sessions.isEmpty) return {};

  final repo = ref.read(workoutRepositoryProvider);
  final sessionIds = sessions.map((s) => s.id).toList();
  final allSets = await repo.getSetsBySessionIds(sessionIds);

  return allSets.map((s) => s.sessionId).toSet();
});

final sessionSetsProvider = FutureProvider.family<List<WorkoutSet>, String>((ref, sessionId) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.getSetsBySession(sessionId);
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sessionsAsync = ref.watch(sessionsProvider);
    final sessionsWithSetsAsync = ref.watch(sessionsWithSetsProvider);
    final sessionsWithSets = sessionsWithSetsAsync.valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
      ),
      floatingActionButton: _selectedDay != null
          ? FloatingActionButton(
              onPressed: () async {
                final sessionId = const Uuid().v4();
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SessionScreen(
                      sessionId: sessionId,
                      initialDate: _selectedDay,
                    ),
                  ),
                );
                if (result == true) {
                  ref.invalidate(sessionsProvider);
                  ref.invalidate(sessionsWithSetsProvider);
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          sessionsAsync.when(
            loading: () => _buildCalendar([], {}),
            error: (e, _) => _buildCalendar([], {}),
            data: (sessions) => _buildCalendar(sessions, sessionsWithSets),
          ),
          const Divider(),
          Expanded(
            child: _selectedDay == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 48,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.selectDate,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : sessionsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('${l10n.error}: $e')),
                    data: (sessions) => _buildDayDetail(sessions),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(List<WorkoutSession> sessions, Set<String> sessionsWithSets) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        final hasWorkout = sessions
            .any((s) => isSameDay(s.date, day) && sessionsWithSets.contains(s.id));
        return hasWorkout ? [true] : [];
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        markerDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
      ),
    );
  }

  Widget _buildDayDetail(List<WorkoutSession> sessions) {
    final l10n = AppLocalizations.of(context);
    final daySessions = sessions.where((s) => isSameDay(s.date, _selectedDay)).toList();

    if (daySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.dateFormat(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day),
              style: const TextStyle(fontSize: AppTypo.titleSm, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.noWorkoutRecord,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return _SessionDetailView(
      sessions: daySessions,
      selectedDay: _selectedDay!,
    );
  }
}

class _SessionDetailView extends ConsumerStatefulWidget {
  final List<WorkoutSession> sessions;
  final DateTime selectedDay;

  const _SessionDetailView({
    required this.sessions,
    required this.selectedDay,
  });

  @override
  ConsumerState<_SessionDetailView> createState() => _SessionDetailViewState();
}

class _SessionDetailViewState extends ConsumerState<_SessionDetailView> {
  List<WorkoutSet>? _allSets;
  Map<String, Exercise>? _exercises;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant _SessionDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions != widget.sessions ||
        oldWidget.selectedDay != widget.selectedDay) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final exerciseRepo = ref.read(exerciseRepositoryProvider);

    final allSets = <WorkoutSet>[];
    for (final session in widget.sessions) {
      final sets = await workoutRepo.getSetsBySession(session.id);
      allSets.addAll(sets);
    }

    final exerciseIds = allSets.map((s) => s.exerciseId).toSet().toList();
    final exercises = <String, Exercise>{};
    for (final id in exerciseIds) {
      final exercise = await exerciseRepo.getExerciseById(id);
      if (exercise != null) {
        exercises[id] = exercise;
      }
    }

    if (mounted) {
      setState(() {
        _allSets = allSets;
        _exercises = exercises;
        _isLoading = false;
      });
    }
  }

  String _getExerciseName(Exercise? exercise, bool isKorean) {
    if (exercise == null) return '';
    try {
      final defaultEx = defaultExercises.firstWhere((e) => e.id == exercise.id);
      return defaultEx.getName(isKorean);
    } catch (_) {
      return exercise.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isKorean = l10n.isKorean;
    final settings = ref.watch(settingsProvider);
    final unitLabel = settings.weightUnit == WeightUnit.kg ? 'kg' : 'lbs';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allSets = _allSets;
    if (allSets == null || allSets.isEmpty) {
      return Center(
        child: Text(l10n.noSetRecord, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }

    final exercises = _exercises ?? {};
    final groupedSets = <String, List<WorkoutSet>>{};
    for (final set in allSets) {
      groupedSets.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          l10n.dateFormat(widget.selectedDay.year, widget.selectedDay.month, widget.selectedDay.day),
          style: const TextStyle(fontSize: AppTypo.titleSm, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        ...groupedSets.entries.map((entry) {
          final exercise = exercises[entry.key];
          final exerciseSets = entry.value;
          final exerciseName = exercise != null
              ? _getExerciseName(exercise, isKorean)
              : l10n.unknownExercise;
          final sessionId = exerciseSets.first.sessionId;
          final exerciseId = entry.key;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showActionSheet(
                l10n,
                sessionId,
                exerciseId,
                exerciseName,
                exerciseSets,
                exercise,
              ),
              borderRadius: AppRadius.mdAll,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exerciseName,
                            style: const TextStyle(
                              fontSize: AppTypo.bodyLg,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.more_vert,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...exerciseSets.asMap().entries.map((e) {
                      final idx = e.key;
                      final set = e.value;
                      final isCardio = set.durationSeconds != null || set.distanceKm != null;

                      if (isCardio) {
                        final durationMin = set.durationSeconds != null
                            ? (set.durationSeconds! / 60).toStringAsFixed(0)
                            : '-';
                        final distanceUnit = settings.weightUnit == WeightUnit.lbs ? 'mi' : 'km';
                        final displayDistance = set.distanceKm != null
                            ? (settings.weightUnit == WeightUnit.lbs
                                ? (set.distanceKm! * 0.621371).toStringAsFixed(2)
                                : set.distanceKm!.toStringAsFixed(2))
                            : '-';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${l10n.set} ${idx + 1}: ${durationMin}min • $displayDistance$distanceUnit',
                            style: const TextStyle(fontSize: AppTypo.bodyMd),
                          ),
                        );
                      }

                      final displayWeight = settings.weightUnit == WeightUnit.lbs
                          ? ((set.weightKg ?? 0) * 2.20462).toStringAsFixed(1)
                          : (set.weightKg ?? 0).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${l10n.set} ${idx + 1}: $displayWeight$unitLabel × ${set.reps ?? 0} ${l10n.reps}',
                          style: const TextStyle(fontSize: AppTypo.bodyMd),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showActionSheet(
    AppLocalizations l10n,
    String sessionId,
    String exerciseId,
    String exerciseName,
    List<WorkoutSet> exerciseSets,
    Exercise? exercise,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editRecord),
              onTap: () async {
                Navigator.pop(sheetContext);
                final exerciseTypeStr = exercise?.exerciseType ?? 'strength';
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => SessionScreen(
                      sessionId: sessionId,
                      editExerciseId: exerciseId,
                      editExerciseName: exerciseName,
                      editExerciseType: exerciseTypeStr,
                      editExistingSets: exerciseSets,
                    ),
                  ),
                );
                if (result == true) {
                  ref.invalidate(sessionsProvider);
                  ref.invalidate(sessionsWithSetsProvider);
                  _loadData();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(l10n.deleteRecord, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteDialog(l10n, sessionId, exerciseId, exerciseName);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    AppLocalizations l10n,
    String sessionId,
    String exerciseId,
    String exerciseName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteRecord),
        content: Text(l10n.deleteExerciseConfirm(exerciseName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final repo = ref.read(workoutRepositoryProvider);
              await repo.deleteSetsByExercise(sessionId, exerciseId);
              ref.invalidate(sessionsProvider);
              ref.invalidate(sessionsWithSetsProvider);
              _loadData();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
