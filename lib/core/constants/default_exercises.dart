import 'exercise_type.dart';

class DefaultExercise {
  final String id;
  final String nameKo;
  final String nameEn;
  final String categoryKo;
  final String categoryEn;
  final String muscleGroupKo;
  final String muscleGroupEn;
  final ExerciseType exerciseType;

  const DefaultExercise({
    required this.id,
    required this.nameKo,
    required this.nameEn,
    required this.categoryKo,
    required this.categoryEn,
    required this.muscleGroupKo,
    required this.muscleGroupEn,
    this.exerciseType = ExerciseType.strength,
  });

  String getName(bool isKorean) => isKorean ? nameKo : nameEn;
  String getCategory(bool isKorean) => isKorean ? categoryKo : categoryEn;
  String getMuscleGroup(bool isKorean) => isKorean ? muscleGroupKo : muscleGroupEn;
}

const List<DefaultExercise> defaultExercises = [
  // Chest
  DefaultExercise(
    id: 'default-bench-press',
    nameKo: '벤치프레스',
    nameEn: 'Bench Press',
    categoryKo: '가슴',
    categoryEn: 'Chest',
    muscleGroupKo: '대흉근, 삼두근',
    muscleGroupEn: 'Pectorals, Triceps',
  ),
  DefaultExercise(
    id: 'default-incline-bench',
    nameKo: '인클라인 벤치프레스',
    nameEn: 'Incline Bench Press',
    categoryKo: '가슴',
    categoryEn: 'Chest',
    muscleGroupKo: '상부 대흉근',
    muscleGroupEn: 'Upper Pectorals',
  ),
  DefaultExercise(
    id: 'default-dumbbell-fly',
    nameKo: '덤벨 플라이',
    nameEn: 'Dumbbell Fly',
    categoryKo: '가슴',
    categoryEn: 'Chest',
    muscleGroupKo: '대흉근',
    muscleGroupEn: 'Pectorals',
  ),
  // Back
  DefaultExercise(
    id: 'default-deadlift',
    nameKo: '데드리프트',
    nameEn: 'Deadlift',
    categoryKo: '등',
    categoryEn: 'Back',
    muscleGroupKo: '척추기립근, 햄스트링',
    muscleGroupEn: 'Erector Spinae, Hamstrings',
  ),
  DefaultExercise(
    id: 'default-pullup',
    nameKo: '풀업',
    nameEn: 'Pull-up',
    categoryKo: '등',
    categoryEn: 'Back',
    muscleGroupKo: '광배근, 이두근',
    muscleGroupEn: 'Latissimus Dorsi, Biceps',
  ),
  DefaultExercise(
    id: 'default-barbell-row',
    nameKo: '바벨 로우',
    nameEn: 'Barbell Row',
    categoryKo: '등',
    categoryEn: 'Back',
    muscleGroupKo: '광배근, 능형근',
    muscleGroupEn: 'Latissimus Dorsi, Rhomboids',
  ),
  DefaultExercise(
    id: 'default-lat-pulldown',
    nameKo: '랫 풀다운',
    nameEn: 'Lat Pulldown',
    categoryKo: '등',
    categoryEn: 'Back',
    muscleGroupKo: '광배근',
    muscleGroupEn: 'Latissimus Dorsi',
  ),
  // Legs
  DefaultExercise(
    id: 'default-squat',
    nameKo: '스쿼트',
    nameEn: 'Squat',
    categoryKo: '하체',
    categoryEn: 'Legs',
    muscleGroupKo: '대퇴사두근, 둔근',
    muscleGroupEn: 'Quadriceps, Glutes',
  ),
  DefaultExercise(
    id: 'default-leg-press',
    nameKo: '레그 프레스',
    nameEn: 'Leg Press',
    categoryKo: '하체',
    categoryEn: 'Legs',
    muscleGroupKo: '대퇴사두근',
    muscleGroupEn: 'Quadriceps',
  ),
  DefaultExercise(
    id: 'default-leg-curl',
    nameKo: '레그 컬',
    nameEn: 'Leg Curl',
    categoryKo: '하체',
    categoryEn: 'Legs',
    muscleGroupKo: '햄스트링',
    muscleGroupEn: 'Hamstrings',
  ),
  DefaultExercise(
    id: 'default-calf-raise',
    nameKo: '카프 레이즈',
    nameEn: 'Calf Raise',
    categoryKo: '하체',
    categoryEn: 'Legs',
    muscleGroupKo: '종아리',
    muscleGroupEn: 'Calves',
  ),
  // Shoulders
  DefaultExercise(
    id: 'default-ohp',
    nameKo: '오버헤드프레스',
    nameEn: 'Overhead Press',
    categoryKo: '어깨',
    categoryEn: 'Shoulders',
    muscleGroupKo: '삼각근, 삼두근',
    muscleGroupEn: 'Deltoids, Triceps',
  ),
  DefaultExercise(
    id: 'default-lateral-raise',
    nameKo: '레터럴 레이즈',
    nameEn: 'Lateral Raise',
    categoryKo: '어깨',
    categoryEn: 'Shoulders',
    muscleGroupKo: '측면 삼각근',
    muscleGroupEn: 'Lateral Deltoids',
  ),
  DefaultExercise(
    id: 'default-face-pull',
    nameKo: '페이스 풀',
    nameEn: 'Face Pull',
    categoryKo: '어깨',
    categoryEn: 'Shoulders',
    muscleGroupKo: '후면 삼각근',
    muscleGroupEn: 'Rear Deltoids',
  ),
  // Arms
  DefaultExercise(
    id: 'default-bicep-curl',
    nameKo: '바이셉 컬',
    nameEn: 'Bicep Curl',
    categoryKo: '팔',
    categoryEn: 'Arms',
    muscleGroupKo: '이두근',
    muscleGroupEn: 'Biceps',
  ),
  DefaultExercise(
    id: 'default-tricep-pushdown',
    nameKo: '트라이셉 푸시다운',
    nameEn: 'Tricep Pushdown',
    categoryKo: '팔',
    categoryEn: 'Arms',
    muscleGroupKo: '삼두근',
    muscleGroupEn: 'Triceps',
  ),
  DefaultExercise(
    id: 'default-hammer-curl',
    nameKo: '해머 컬',
    nameEn: 'Hammer Curl',
    categoryKo: '팔',
    categoryEn: 'Arms',
    muscleGroupKo: '이두근, 전완근',
    muscleGroupEn: 'Biceps, Forearms',
  ),
  // Cardio
  DefaultExercise(
    id: 'default-treadmill',
    nameKo: '러닝머신',
    nameEn: 'Treadmill',
    categoryKo: '유산소',
    categoryEn: 'Cardio',
    muscleGroupKo: '전신',
    muscleGroupEn: 'Full Body',
    exerciseType: ExerciseType.cardio,
  ),
  DefaultExercise(
    id: 'default-cycling',
    nameKo: '사이클',
    nameEn: 'Cycling',
    categoryKo: '유산소',
    categoryEn: 'Cardio',
    muscleGroupKo: '하체',
    muscleGroupEn: 'Legs',
    exerciseType: ExerciseType.cardio,
  ),
];

class ExerciseCategories {
  static const List<String> ko = [
    '가슴',
    '등',
    '하체',
    '어깨',
    '팔',
    '유산소',
    '기타',
  ];

  static const List<String> en = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Cardio',
    'Other',
  ];

  static List<String> get(bool isKorean) => isKorean ? ko : en;

  static String translate(String category, bool toKorean) {
    final fromList = toKorean ? en : ko;
    final toList = toKorean ? ko : en;
    final index = fromList.indexOf(category);
    if (index >= 0 && index < toList.length) {
      return toList[index];
    }
    return category;
  }
}

class DefaultExerciseHelper {
  static final Map<String, DefaultExercise> _exerciseMap = {
    for (final e in defaultExercises) e.id: e
  };

  static String getDisplayName(String id, String storedName, bool isKorean) {
    final defaultEx = _exerciseMap[id];
    if (defaultEx != null) {
      return isKorean ? defaultEx.nameKo : defaultEx.nameEn;
    }
    return storedName;
  }

  static String getDisplayCategory(String id, String storedCategory, bool isKorean) {
    final defaultEx = _exerciseMap[id];
    if (defaultEx != null) {
      return isKorean ? defaultEx.categoryKo : defaultEx.categoryEn;
    }
    if (ExerciseCategories.ko.contains(storedCategory)) {
      return isKorean ? storedCategory : ExerciseCategories.translate(storedCategory, false);
    }
    if (ExerciseCategories.en.contains(storedCategory)) {
      return isKorean ? ExerciseCategories.translate(storedCategory, true) : storedCategory;
    }
    return storedCategory;
  }

  static String getDisplayMuscleGroup(String id, String? storedMuscleGroup, bool isKorean) {
    final defaultEx = _exerciseMap[id];
    if (defaultEx != null) {
      return isKorean ? defaultEx.muscleGroupKo : defaultEx.muscleGroupEn;
    }
    return storedMuscleGroup ?? '';
  }
}
