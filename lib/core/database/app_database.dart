import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/exercises_table.dart';
import 'tables/workout_sessions_table.dart';
import 'tables/workout_sets_table.dart';
import 'tables/body_records_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Exercises, WorkoutSessions, WorkoutSets, BodyRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'gymlog.db'));
      return NativeDatabase(file);
    });
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Add exerciseType column to exercises table
          await m.addColumn(exercises, exercises.exerciseType);
          await customStatement(
            "UPDATE exercises SET exercise_type = 'cardio' WHERE category IN ('유산소', 'Cardio')",
          );
        }
        if (from < 3) {
          // Recreate workout_sets table to make reps/weightKg nullable and add cardio columns
          await customStatement('''
            CREATE TABLE workout_sets_new (
              id TEXT NOT NULL PRIMARY KEY,
              session_id TEXT NOT NULL REFERENCES workout_sessions(id),
              exercise_id TEXT NOT NULL REFERENCES exercises(id),
              set_number INTEGER NOT NULL,
              reps INTEGER,
              weight_kg REAL,
              duration_seconds INTEGER,
              distance_km REAL,
              rpe INTEGER,
              rest_seconds INTEGER,
              created_at INTEGER NOT NULL,
              updated_at INTEGER NOT NULL,
              sync_status TEXT NOT NULL DEFAULT 'pending'
            )
          ''');
          await customStatement('''
            INSERT INTO workout_sets_new (id, session_id, exercise_id, set_number, reps, weight_kg, rpe, rest_seconds, created_at, updated_at, sync_status)
            SELECT id, session_id, exercise_id, set_number, reps, weight_kg, rpe, rest_seconds, created_at, updated_at, sync_status FROM workout_sets
          ''');
          await customStatement('DROP TABLE workout_sets');
          await customStatement('ALTER TABLE workout_sets_new RENAME TO workout_sets');
        }
      },
    );
  }
}
