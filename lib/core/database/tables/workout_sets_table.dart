import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workout_sessions_table.dart';

class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(WorkoutSessions, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  // Strength training fields
  IntColumn get reps => integer().nullable()();
  RealColumn get weightKg => real().nullable()();
  // Cardio fields
  IntColumn get durationSeconds => integer().nullable()();
  RealColumn get distanceKm => real().nullable()();
  // Optional fields
  IntColumn get rpe => integer().nullable()();
  IntColumn get restSeconds => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
