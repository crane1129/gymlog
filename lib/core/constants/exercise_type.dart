enum ExerciseType {
  strength,
  cardio,
}

extension ExerciseTypeExtension on ExerciseType {
  String get value => name;

  static ExerciseType fromString(String value) {
    return ExerciseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseType.strength,
    );
  }

  bool get requiresWeight => this == ExerciseType.strength;
  bool get requiresReps => this == ExerciseType.strength;
  bool get requiresDuration => this == ExerciseType.cardio;
  bool get requiresDistance => this == ExerciseType.cardio;
}
