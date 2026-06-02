import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/database/app_database.dart';
import 'features/exercise/data/exercise_repository.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/workout/data/workout_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final db = AppDatabase();

  final exerciseRepo = ExerciseRepository(db);
  await exerciseRepo.seedDefaultExercises();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(db),
      ],
      child: const GymLogApp(),
    ),
  );
}
