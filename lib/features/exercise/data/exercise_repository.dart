import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/default_exercises.dart';
import '../../../core/constants/exercise_type.dart';
import '../../../core/database/app_database.dart';
import '../../workout/data/workout_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ExerciseRepository(db);
});

class ExerciseRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  ExerciseRepository(this._db);

  Future<void> seedDefaultExercises() async {
    final now = DateTime.now();
    await _db.transaction(() async {
      for (final defaultEx in defaultExercises) {
        await _db.into(_db.exercises).insertOnConflictUpdate(
              ExercisesCompanion.insert(
                id: defaultEx.id,
                name: defaultEx.nameKo,
                category: defaultEx.categoryKo,
                muscleGroup: Value(defaultEx.muscleGroupKo),
                exerciseType: Value(defaultEx.exerciseType.value),
                isDefault: const Value(true),
                isActive: const Value(true),
                createdAt: now,
                updatedAt: now,
                syncStatus: const Value('synced'),
              ),
            );
      }
    });
  }

  Future<List<Exercise>> getAllExercises() {
    return (_db.select(_db.exercises)
          ..where((e) => e.isActive.equals(true))
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .get();
  }

  Stream<List<Exercise>> watchAllExercises() {
    return (_db.select(_db.exercises)
          ..where((e) => e.isActive.equals(true))
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .watch();
  }

  Future<List<Exercise>> getExercisesByCategory(String category) {
    return (_db.select(_db.exercises)
          ..where((e) => e.isActive.equals(true) & e.category.equals(category))
          ..orderBy([(e) => OrderingTerm.asc(e.name)]))
        .get();
  }

  Future<Exercise?> getExerciseById(String id) {
    return (_db.select(_db.exercises)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> createExercise({
    required String name,
    required String category,
    String? muscleGroup,
    String? imagePath,
    ExerciseType exerciseType = ExerciseType.strength,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(
            id: id,
            name: name,
            category: category,
            muscleGroup: Value(muscleGroup),
            imagePath: Value(imagePath),
            exerciseType: Value(exerciseType.value),
            isDefault: const Value(false),
            isActive: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  Future<void> updateExercise(String id, {String? name, String? category, String? muscleGroup, Value<String?> imagePath = const Value.absent()}) async {
    await (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        muscleGroup: muscleGroup != null ? Value(muscleGroup) : const Value.absent(),
        imagePath: imagePath,
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteExercise(String id) async {
    await (_db.update(_db.exercises)..where((e) => e.id.equals(id))).write(
      ExercisesCompanion(
        isActive: const Value(false),
        syncStatus: const Value('deleted'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
