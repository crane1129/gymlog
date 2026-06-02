import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../../constants/default_exercises.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Stream<List<Exercise>> watchAllExercises() =>
      (select(exercises)..where((e) => e.isActive.equals(true))).watch();

  Future<Exercise?> getExerciseById(String id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertExercise(ExercisesCompanion exercise) =>
      into(exercises).insert(exercise);

  Future<bool> updateExercise(ExercisesCompanion exercise) =>
      update(exercises).replace(Exercise(
        id: exercise.id.value,
        name: exercise.name.value,
        category: exercise.category.value,
        muscleGroup: exercise.muscleGroup.value,
        exerciseType: exercise.exerciseType.present ? exercise.exerciseType.value : 'strength',
        isDefault: exercise.isDefault.value,
        isActive: exercise.isActive.value,
        createdAt: exercise.createdAt.value,
        updatedAt: exercise.updatedAt.value,
        syncStatus: exercise.syncStatus.value,
      ));

  Future<int> deleteExercise(String id) =>
      (delete(exercises)..where((e) => e.id.equals(id))).go();

  Future<void> seedDefaultExercises() async {
    final now = DateTime.now();
    for (final defaultEx in defaultExercises) {
      final existing = await getExerciseById(defaultEx.id);
      if (existing == null) {
        await insertExercise(ExercisesCompanion.insert(
          id: defaultEx.id,
          name: defaultEx.nameKo,
          category: defaultEx.categoryKo,
          muscleGroup: Value(defaultEx.muscleGroupKo),
          isDefault: const Value(true),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
          syncStatus: const Value('synced'),
        ));
      }
    }
  }
}
