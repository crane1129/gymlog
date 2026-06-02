import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workout/data/workout_repository.dart';
import '../../body/data/body_repository.dart';
import '../../exercise/data/exercise_repository.dart';

final importServiceProvider = Provider<ImportService>((ref) {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final bodyRepo = ref.watch(bodyRepositoryProvider);
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);
  return ImportService(workoutRepo, bodyRepo, exerciseRepo);
});

class ImportResult {
  final int workoutSetsImported;
  final int bodyRecordsImported;
  final int exercisesCreated;
  final List<String> errors;

  ImportResult({
    this.workoutSetsImported = 0,
    this.bodyRecordsImported = 0,
    this.exercisesCreated = 0,
    this.errors = const [],
  });

  ImportResult copyWith({
    int? workoutSetsImported,
    int? bodyRecordsImported,
    int? exercisesCreated,
    List<String>? errors,
  }) {
    return ImportResult(
      workoutSetsImported: workoutSetsImported ?? this.workoutSetsImported,
      bodyRecordsImported: bodyRecordsImported ?? this.bodyRecordsImported,
      exercisesCreated: exercisesCreated ?? this.exercisesCreated,
      errors: errors ?? this.errors,
    );
  }

  bool get hasErrors => errors.isNotEmpty;
  bool get hasData => workoutSetsImported > 0 || bodyRecordsImported > 0;
}

class ImportService {
  final WorkoutRepository _workoutRepo;
  final BodyRepository _bodyRepo;
  final ExerciseRepository _exerciseRepo;

  ImportService(this._workoutRepo, this._bodyRepo, this._exerciseRepo);

  Future<ImportResult?> importFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    var importResult = ImportResult();
    final errors = <String>[];

    for (final file in result.files) {
      if (file.path == null) continue;

      try {
        final content = await _readFileContent(file.path!);
        final fileName = file.name.toLowerCase();

        if (fileName.contains('workout')) {
          final workoutResult = await _importWorkoutCsv(content);
          importResult = importResult.copyWith(
            workoutSetsImported: importResult.workoutSetsImported + workoutResult.workoutSetsImported,
            exercisesCreated: importResult.exercisesCreated + workoutResult.exercisesCreated,
            errors: [...importResult.errors, ...workoutResult.errors],
          );
        } else if (fileName.contains('body')) {
          final bodyResult = await _importBodyCsv(content);
          importResult = importResult.copyWith(
            bodyRecordsImported: importResult.bodyRecordsImported + bodyResult.bodyRecordsImported,
            errors: [...importResult.errors, ...bodyResult.errors],
          );
        } else {
          final workoutResult = await _importWorkoutCsv(content);
          if (workoutResult.hasData) {
            importResult = importResult.copyWith(
              workoutSetsImported: importResult.workoutSetsImported + workoutResult.workoutSetsImported,
              exercisesCreated: importResult.exercisesCreated + workoutResult.exercisesCreated,
              errors: [...importResult.errors, ...workoutResult.errors],
            );
          } else {
            final bodyResult = await _importBodyCsv(content);
            importResult = importResult.copyWith(
              bodyRecordsImported: importResult.bodyRecordsImported + bodyResult.bodyRecordsImported,
              errors: [...importResult.errors, ...bodyResult.errors],
            );
          }
        }
      } catch (e) {
        errors.add('${file.name}: $e');
      }
    }

    if (errors.isNotEmpty) {
      importResult = importResult.copyWith(
        errors: [...importResult.errors, ...errors],
      );
    }

    return importResult;
  }

  Future<String> _readFileContent(String path) async {
    final file = File(path);
    final bytes = await file.readAsBytes();

    if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3));
    }
    return utf8.decode(bytes);
  }

  Future<ImportResult> _importWorkoutCsv(String content) async {
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return ImportResult();

    final header = _parseCsvLine(lines.first);
    final dateIdx = _findColumnIndex(header, ['date', '날짜']);
    final exerciseIdx = _findColumnIndex(header, ['exercise', '운동', '운동명']);
    final setIdx = _findColumnIndex(header, ['set', '세트']);
    final weightIdx = _findColumnIndex(header, ['weight', '무게', 'weight (kg)']);
    final repsIdx = _findColumnIndex(header, ['reps', '횟수', '반복']);
    final durationIdx = _findColumnIndex(header, ['duration', '시간', 'duration (seconds)']);
    final distanceIdx = _findColumnIndex(header, ['distance', '거리', 'distance (km)']);

    if (dateIdx == -1 || exerciseIdx == -1) {
      return ImportResult();
    }

    final exercises = await _exerciseRepo.getAllExercises();
    final exerciseNameToId = <String, String>{};
    for (final e in exercises) {
      exerciseNameToId[e.name.toLowerCase()] = e.id;
    }

    var setsImported = 0;
    var exercisesCreated = 0;
    final errors = <String>[];
    final sessionCache = <String, String>{};

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _parseCsvLine(line);
        if (fields.length <= dateIdx || fields.length <= exerciseIdx) {
          continue;
        }

        final dateStr = fields[dateIdx];
        final exerciseName = fields[exerciseIdx];
        final setNumber = setIdx != -1 && fields.length > setIdx ? int.tryParse(fields[setIdx]) ?? 1 : 1;

        final weight = weightIdx != -1 && fields.length > weightIdx && fields[weightIdx].isNotEmpty
            ? double.tryParse(fields[weightIdx].replaceAll(',', '.'))
            : null;
        final reps = repsIdx != -1 && fields.length > repsIdx && fields[repsIdx].isNotEmpty
            ? int.tryParse(fields[repsIdx])
            : null;
        final duration = durationIdx != -1 && fields.length > durationIdx && fields[durationIdx].isNotEmpty
            ? int.tryParse(fields[durationIdx])
            : null;
        final distance = distanceIdx != -1 && fields.length > distanceIdx && fields[distanceIdx].isNotEmpty
            ? double.tryParse(fields[distanceIdx].replaceAll(',', '.'))
            : null;

        final hasStrengthData = weight != null || reps != null;
        final hasCardioData = duration != null || distance != null;

        if (!hasStrengthData && !hasCardioData) {
          continue;
        }

        final date = _parseDate(dateStr);
        if (date == null) {
          errors.add('Line ${i + 1}: Invalid date format');
          continue;
        }

        var exerciseId = exerciseNameToId[exerciseName.toLowerCase()];
        if (exerciseId == null) {
          exerciseId = await _exerciseRepo.createExercise(
            name: exerciseName,
            category: 'Custom',
          );
          exerciseNameToId[exerciseName.toLowerCase()] = exerciseId;
          exercisesCreated++;
        }

        final dateKey = '${date.year}-${date.month}-${date.day}';
        var sessionId = sessionCache[dateKey];
        if (sessionId == null) {
          sessionId = await _workoutRepo.getOrCreateSession(date);
          sessionCache[dateKey] = sessionId;
        }

        await _workoutRepo.addSet(
          sessionId: sessionId,
          exerciseId: exerciseId,
          setNumber: setNumber,
          reps: reps,
          weightKg: weight,
          durationSeconds: duration,
          distanceKm: distance,
        );
        setsImported++;
      } catch (e) {
        errors.add('Line ${i + 1}: $e');
      }
    }

    return ImportResult(
      workoutSetsImported: setsImported,
      exercisesCreated: exercisesCreated,
      errors: errors,
    );
  }

  Future<ImportResult> _importBodyCsv(String content) async {
    final lines = const LineSplitter().convert(content);
    if (lines.isEmpty) return ImportResult();

    final header = _parseCsvLine(lines.first);
    final dateIdx = _findColumnIndex(header, ['date', '날짜']);
    final weightIdx = _findColumnIndex(header, ['weight', '체중', 'weight (kg)']);

    if (dateIdx == -1 || weightIdx == -1) {
      return ImportResult();
    }

    var recordsImported = 0;
    final errors = <String>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _parseCsvLine(line);
        if (fields.length <= [dateIdx, weightIdx].reduce((a, b) => a > b ? a : b)) {
          continue;
        }

        final dateStr = fields[dateIdx];
        final weight = double.tryParse(fields[weightIdx].replaceAll(',', '.'));

        if (weight == null) {
          errors.add('Line ${i + 1}: Invalid weight');
          continue;
        }

        final date = _parseDate(dateStr);
        if (date == null) {
          errors.add('Line ${i + 1}: Invalid date format');
          continue;
        }

        await _bodyRepo.addOrUpdateRecord(
          date: date,
          weightKg: weight,
        );
        recordsImported++;
      } catch (e) {
        errors.add('Line ${i + 1}: $e');
      }
    }

    return ImportResult(
      bodyRecordsImported: recordsImported,
      errors: errors,
    );
  }

  int _findColumnIndex(List<String> header, List<String> possibleNames) {
    for (var i = 0; i < header.length; i++) {
      final col = header[i].toLowerCase().trim();
      for (final name in possibleNames) {
        if (col == name || col.contains(name)) {
          return i;
        }
      }
    }
    return -1;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  DateTime? _parseDate(String dateStr) {
    final cleaned = dateStr.trim();

    final isoMatch = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(cleaned);
    if (isoMatch != null) {
      return DateTime(
        int.parse(isoMatch.group(1)!),
        int.parse(isoMatch.group(2)!),
        int.parse(isoMatch.group(3)!),
      );
    }

    final usMatch = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})').firstMatch(cleaned);
    if (usMatch != null) {
      return DateTime(
        int.parse(usMatch.group(3)!),
        int.parse(usMatch.group(1)!),
        int.parse(usMatch.group(2)!),
      );
    }

    return null;
  }
}
