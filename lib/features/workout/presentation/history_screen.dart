import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/app_localizations.dart';
import '../data/workout_repository.dart';
import '../../exercise/data/exercise_repository.dart';
import '../../settings/data/settings_repository.dart';

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
                    child: Text(
                      l10n.selectDate,
                      style: const TextStyle(color: Colors.grey),
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
        return sessions
            .where((s) => isSameDay(s.date, day) && sessionsWithSets.contains(s.id))
            .toList();
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
            Text(
              l10n.dateFormat(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noWorkoutRecord,
              style: const TextStyle(color: Colors.grey),
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

class _SessionDetailView extends ConsumerWidget {
  final List<WorkoutSession> sessions;
  final DateTime selectedDay;

  const _SessionDetailView({
    required this.sessions,
    required this.selectedDay,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isKorean = l10n.isKorean;
    final exerciseRepo = ref.watch(exerciseRepositoryProvider);
    final workoutRepo = ref.watch(workoutRepositoryProvider);
    final settings = ref.watch(settingsProvider);
    final unitLabel = settings.weightUnit == WeightUnit.kg ? 'kg' : 'lbs';

    return FutureBuilder<List<WorkoutSet>>(
      future: _loadAllSets(workoutRepo),
      builder: (context, setsSnapshot) {
        if (!setsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allSets = setsSnapshot.data!;

        if (allSets.isEmpty) {
          return Center(
            child: Text(l10n.noSetRecord, style: const TextStyle(color: Colors.grey)),
          );
        }

        final exerciseIds = allSets.map((s) => s.exerciseId).toSet().toList();

        return FutureBuilder<Map<String, Exercise>>(
          future: _loadExercises(exerciseRepo, exerciseIds),
          builder: (context, exerciseSnapshot) {
            if (!exerciseSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final exercises = exerciseSnapshot.data!;
            final groupedSets = <String, List<WorkoutSet>>{};

            for (final set in allSets) {
              groupedSets.putIfAbsent(set.exerciseId, () => []).add(set);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  l10n.dateFormat(selectedDay.year, selectedDay.month, selectedDay.day),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
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
                      onTap: () => _showDeleteDialog(
                        context,
                        ref,
                        l10n,
                        sessionId,
                        exerciseId,
                        exerciseName,
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.more_vert,
                                  size: 20,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
                                    style: const TextStyle(fontSize: 14),
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
                                  style: const TextStyle(fontSize: 14),
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
          },
        );
      },
    );
  }

  Future<List<WorkoutSet>> _loadAllSets(WorkoutRepository repo) async {
    final allSets = <WorkoutSet>[];
    for (final session in sessions) {
      final sets = await repo.getSetsBySession(session.id);
      allSets.addAll(sets);
    }
    return allSets;
  }

  Future<Map<String, Exercise>> _loadExercises(
    ExerciseRepository repo,
    List<String> ids,
  ) async {
    final map = <String, Exercise>{};
    for (final id in ids) {
      final exercise = await repo.getExerciseById(id);
      if (exercise != null) {
        map[id] = exercise;
      }
    }
    return map;
  }

  void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
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
