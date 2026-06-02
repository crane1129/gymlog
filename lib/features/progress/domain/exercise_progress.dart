class ExerciseProgressPoint {
  final DateTime date;
  final double? maxWeight;
  final int? maxReps;
  final double? totalVolume;
  final int? maxDurationSeconds;
  final double? maxDistanceKm;
  final int? totalDurationSeconds;
  final double? totalDistanceKm;
  final int setCount;

  const ExerciseProgressPoint({
    required this.date,
    this.maxWeight,
    this.maxReps,
    this.totalVolume,
    this.maxDurationSeconds,
    this.maxDistanceKm,
    this.totalDurationSeconds,
    this.totalDistanceKm,
    required this.setCount,
  });
}

enum ExerciseDataType {
  weightAndReps,
  weightOnly,
  repsOnly,
  cardio,
}

class ExerciseProgress {
  final String exerciseId;
  final String exerciseName;
  final ExerciseDataType dataType;
  final List<ExerciseProgressPoint> points;
  final double? currentMaxWeight;
  final int? currentMaxReps;
  final double? previousMaxWeight;
  final int? previousMaxReps;
  final int? currentMaxDuration;
  final double? currentMaxDistance;
  final int? previousMaxDuration;
  final double? previousMaxDistance;

  const ExerciseProgress({
    required this.exerciseId,
    required this.exerciseName,
    required this.dataType,
    required this.points,
    this.currentMaxWeight,
    this.currentMaxReps,
    this.previousMaxWeight,
    this.previousMaxReps,
    this.currentMaxDuration,
    this.currentMaxDistance,
    this.previousMaxDuration,
    this.previousMaxDistance,
  });

  double? get weightChange {
    if (currentMaxWeight == null || previousMaxWeight == null) return null;
    if (previousMaxWeight == 0) return null;
    return currentMaxWeight! - previousMaxWeight!;
  }

  int? get repsChange {
    if (currentMaxReps == null || previousMaxReps == null) return null;
    return currentMaxReps! - previousMaxReps!;
  }

  int? get durationChange {
    if (currentMaxDuration == null || previousMaxDuration == null) return null;
    return currentMaxDuration! - previousMaxDuration!;
  }

  double? get distanceChange {
    if (currentMaxDistance == null || previousMaxDistance == null) return null;
    return currentMaxDistance! - previousMaxDistance!;
  }

  bool get hasWeightData => dataType == ExerciseDataType.weightAndReps ||
                            dataType == ExerciseDataType.weightOnly;

  bool get hasRepsData => dataType == ExerciseDataType.weightAndReps ||
                          dataType == ExerciseDataType.repsOnly;

  bool get isCardio => dataType == ExerciseDataType.cardio;
}
