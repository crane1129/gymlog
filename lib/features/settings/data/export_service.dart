import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../workout/data/workout_repository.dart';
import '../../body/data/body_repository.dart';
import '../../exercise/data/exercise_repository.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final bodyRepo = ref.watch(bodyRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);
  return ExportService(workoutRepo, bodyRepo, exerciseRepo);
});

class ExportService {
  final WorkoutRepository _workoutRepo;
  final BodyRepository _bodyRepo;
  final ExerciseRepository _exerciseRepo;

  ExportService(this._workoutRepo, this._bodyRepo, this._exerciseRepo);

  Future<void> exportAllData({Rect? sharePositionOrigin}) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final files = <XFile>[];

    final workoutCsv = await _generateWorkoutCsv();
    if (workoutCsv.isNotEmpty) {
      final workoutFile = File('${tempDir.path}/gymlog_workouts_$timestamp.csv');
      await _writeUtf8BomFile(workoutFile, workoutCsv);
      files.add(XFile(workoutFile.path));
    }

    final bodyCsv = await _generateBodyCsv();
    if (bodyCsv.isNotEmpty) {
      final bodyFile = File('${tempDir.path}/gymlog_body_$timestamp.csv');
      await _writeUtf8BomFile(bodyFile, bodyCsv);
      files.add(XFile(bodyFile.path));
    }

    if (files.isEmpty) {
      throw Exception('No data to export');
    }

    await Share.shareXFiles(
      files,
      subject: 'GymLog Data Export',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  Future<String> _generateWorkoutCsv() async {
    final sessions = await _workoutRepo.getAllSessions();
    if (sessions.isEmpty) return '';

    final exercises = await _exerciseRepo.getAllExercises();
    final exerciseMap = {for (var e in exercises) e.id: e.name};

    final buffer = StringBuffer();
    buffer.writeln('Date,Exercise,Set,Weight (kg),Reps,Duration (seconds),Distance (km)');

    for (final session in sessions) {
      final sets = await _workoutRepo.getSetsBySession(session.id);
      for (final set in sets) {
        final exerciseName = _escapeCsv(exerciseMap[set.exerciseId] ?? 'Unknown');
        final dateStr = _formatDate(session.date);
        final weight = set.weightKg?.toString() ?? '';
        final reps = set.reps?.toString() ?? '';
        final duration = set.durationSeconds?.toString() ?? '';
        final distance = set.distanceKm?.toString() ?? '';
        buffer.writeln('$dateStr,$exerciseName,${set.setNumber},$weight,$reps,$duration,$distance');
      }
    }

    return buffer.toString();
  }

  Future<String> _generateBodyCsv() async {
    final records = await _bodyRepo.getAllRecords();
    if (records.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('Date,Weight (kg)');

    for (final record in records) {
      final dateStr = _formatDate(record.date);
      buffer.writeln('$dateStr,${record.weightKg}');
    }

    return buffer.toString();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  Future<void> _writeUtf8BomFile(File file, String content) async {
    final bom = [0xEF, 0xBB, 0xBF];
    final contentBytes = utf8.encode(content);
    final bytes = [...bom, ...contentBytes];
    await file.writeAsBytes(bytes);
  }
}
