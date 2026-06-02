import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});

class WorkoutRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  WorkoutRepository(this._db);

  Future<String> getOrCreateSession(DateTime date, {String? id}) async {
    // 같은 날짜에 이미 세션이 있는지 확인
    final existing = await getSessionByDate(date);
    if (existing != null) {
      return existing.id;
    }

    // 없으면 새 세션 생성
    final sessionId = id ?? _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            id: sessionId,
            date: date,
            createdAt: now,
            updatedAt: now,
          ),
        );

    return sessionId;
  }

  Future<void> updateSession(String id, {int? durationMinutes, String? note}) async {
    await (_db.update(_db.workoutSessions)..where((s) => s.id.equals(id))).write(
      WorkoutSessionsCompanion(
        durationMinutes: Value(durationMinutes),
        note: Value(note),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addSet({
    required String sessionId,
    required String exerciseId,
    required int setNumber,
    // Strength training fields
    int? reps,
    double? weightKg,
    // Cardio fields
    int? durationSeconds,
    double? distanceKm,
    // Optional fields
    int? rpe,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.workoutSets).insert(
          WorkoutSetsCompanion.insert(
            id: id,
            sessionId: sessionId,
            exerciseId: exerciseId,
            setNumber: setNumber,
            reps: Value(reps),
            weightKg: Value(weightKg),
            durationSeconds: Value(durationSeconds),
            distanceKm: Value(distanceKm),
            rpe: Value(rpe),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> deleteSetsBySession(String sessionId) async {
    await (_db.delete(_db.workoutSets)
          ..where((s) => s.sessionId.equals(sessionId)))
        .go();
  }

  Future<void> deleteSetsByExercise(String sessionId, String exerciseId) async {
    await (_db.delete(_db.workoutSets)
          ..where((s) =>
              s.sessionId.equals(sessionId) & s.exerciseId.equals(exerciseId)))
        .go();
  }

  Future<List<WorkoutSession>> getAllSessions() {
    return (_db.select(_db.workoutSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  Stream<List<WorkoutSession>> watchAllSessions() {
    return (_db.select(_db.workoutSessions)
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .watch();
  }

  Future<WorkoutSession?> getSessionByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (_db.select(_db.workoutSessions)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(startOfDay) &
              s.date.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  Future<List<WorkoutSet>> getSetsBySession(String sessionId) {
    return (_db.select(_db.workoutSets)
          ..where((s) => s.sessionId.equals(sessionId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.exerciseId),
            (s) => OrderingTerm.asc(s.setNumber),
          ]))
        .get();
  }

  Future<List<WorkoutSession>> getSessionsByDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.workoutSessions)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(start) &
              s.date.isSmallerThanValue(end))
          ..orderBy([(s) => OrderingTerm.desc(s.date)]))
        .get();
  }

  Future<List<WorkoutSet>> getSetsBySessionIds(List<String> sessionIds) {
    if (sessionIds.isEmpty) return Future.value([]);
    return (_db.select(_db.workoutSets)
          ..where((s) => s.sessionId.isIn(sessionIds)))
        .get();
  }

  Stream<List<WorkoutSet>> watchSetsBySession(String sessionId) {
    return (_db.select(_db.workoutSets)
          ..where((s) => s.sessionId.equals(sessionId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.exerciseId),
            (s) => OrderingTerm.asc(s.setNumber),
          ]))
        .watch();
  }

  Future<void> deleteAllWorkoutData() async {
    await _db.delete(_db.workoutSets).go();
    await _db.delete(_db.workoutSessions).go();
  }

  Future<void> deleteAllBodyData() async {
    await _db.delete(_db.bodyRecords).go();
  }

  Future<void> deleteAllData() async {
    await deleteAllWorkoutData();
    await deleteAllBodyData();
  }

  Future<List<WorkoutSet>> getSetsByExerciseAndDateRange(
    String exerciseId,
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await getSessionsByDateRange(start, end);
    if (sessions.isEmpty) return [];

    final sessionIds = sessions.map((s) => s.id).toList();
    final allSets = await getSetsBySessionIds(sessionIds);

    return allSets.where((s) => s.exerciseId == exerciseId).toList();
  }

  Future<Map<String, List<WorkoutSet>>> getSetsByExercisesAndDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await getSessionsByDateRange(start, end);
    if (sessions.isEmpty) return {};

    final sessionIds = sessions.map((s) => s.id).toList();
    final allSets = await getSetsBySessionIds(sessionIds);

    final result = <String, List<WorkoutSet>>{};
    for (final set in allSets) {
      result.putIfAbsent(set.exerciseId, () => []).add(set);
    }
    return result;
  }

  Future<Map<String, List<({WorkoutSet set, DateTime sessionDate})>>> getSetsByExercisesWithSessionDate(
    DateTime start,
    DateTime end,
  ) async {
    final sessions = await getSessionsByDateRange(start, end);
    if (sessions.isEmpty) return {};

    final sessionMap = {for (final s in sessions) s.id: s.date};
    final sessionIds = sessions.map((s) => s.id).toList();
    final allSets = await getSetsBySessionIds(sessionIds);

    final result = <String, List<({WorkoutSet set, DateTime sessionDate})>>{};
    for (final set in allSets) {
      final sessionDate = sessionMap[set.sessionId];
      if (sessionDate != null) {
        result.putIfAbsent(set.exerciseId, () => []).add((set: set, sessionDate: sessionDate));
      }
    }
    return result;
  }

  Future<List<String>> getExerciseIdsWithData(DateTime start, DateTime end) async {
    final setsByExercise = await getSetsByExercisesAndDateRange(start, end);
    return setsByExercise.keys.toList();
  }
}
