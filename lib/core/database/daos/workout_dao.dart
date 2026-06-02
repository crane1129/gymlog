import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workout_sessions_table.dart';
import '../tables/workout_sets_table.dart';

part 'workout_dao.g.dart';

@DriftAccessor(tables: [WorkoutSessions, WorkoutSets])
class WorkoutDao extends DatabaseAccessor<AppDatabase> with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // Sessions
  Future<List<WorkoutSession>> getAllSessions() =>
      (select(workoutSessions)..orderBy([(s) => OrderingTerm.desc(s.date)]))
          .get();

  Stream<List<WorkoutSession>> watchAllSessions() =>
      (select(workoutSessions)..orderBy([(s) => OrderingTerm.desc(s.date)]))
          .watch();

  Future<WorkoutSession?> getSessionById(String id) =>
      (select(workoutSessions)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<WorkoutSession?> getSessionByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(workoutSessions)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(startOfDay) &
              s.date.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  Stream<WorkoutSession?> watchSessionByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(workoutSessions)
          ..where((s) =>
              s.date.isBiggerOrEqualValue(startOfDay) &
              s.date.isSmallerThanValue(endOfDay)))
        .watchSingleOrNull();
  }

  Future<int> insertSession(WorkoutSessionsCompanion session) =>
      into(workoutSessions).insert(session);

  Future<bool> updateSession(WorkoutSession session) =>
      update(workoutSessions).replace(session);

  Future<int> deleteSession(String id) =>
      (delete(workoutSessions)..where((s) => s.id.equals(id))).go();

  // Sets
  Future<List<WorkoutSet>> getSetsBySessionId(String sessionId) =>
      (select(workoutSets)
            ..where((s) => s.sessionId.equals(sessionId))
            ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
          .get();

  Stream<List<WorkoutSet>> watchSetsBySessionId(String sessionId) =>
      (select(workoutSets)
            ..where((s) => s.sessionId.equals(sessionId))
            ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
          .watch();

  Future<List<WorkoutSet>> getSetsByExerciseId(String exerciseId) =>
      (select(workoutSets)
            ..where((s) => s.exerciseId.equals(exerciseId))
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
          .get();

  Future<int> insertSet(WorkoutSetsCompanion set) =>
      into(workoutSets).insert(set);

  Future<bool> updateSet(WorkoutSet set) => update(workoutSets).replace(set);

  Future<int> deleteSet(String id) =>
      (delete(workoutSets)..where((s) => s.id.equals(id))).go();

  Future<int> deleteSetsBySessionId(String sessionId) =>
      (delete(workoutSets)..where((s) => s.sessionId.equals(sessionId))).go();
}
