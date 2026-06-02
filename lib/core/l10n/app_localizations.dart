import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isKorean => locale.languageCode == 'ko';

  // Splash
  String get splashTagline => isKorean ? '운동 기록의 시작' : 'Start Your Fitness Journey';

  // Common
  String get appName => 'My Gym Logger';
  String get cancel => isKorean ? '취소' : 'Cancel';
  String get save => isKorean ? '저장' : 'Save';
  String get delete => isKorean ? '삭제' : 'Delete';
  String get close => isKorean ? '닫기' : 'Close';
  String get confirm => isKorean ? '확인' : 'Confirm';
  String get error => isKorean ? '오류' : 'Error';

  // Bottom Navigation
  String get navHome => isKorean ? '홈' : 'Home';
  String get navHistory => isKorean ? '기록' : 'History';
  String get navTimer => isKorean ? '타이머' : 'Timer';
  String get navProgress => isKorean ? '통계' : 'Progress';
  String get navBody => isKorean ? '바디' : 'Body';

  // Home Screen
  String get startWorkout => isKorean ? '운동 시작' : 'Start Workout';
  String get todayWorkout => isKorean ? '오늘의 운동' : "Today's Workout";
  String get noWorkoutToday => isKorean ? '오늘 운동 기록이 없습니다' : 'No workout today';

  // Dashboard
  String get dashboardToday => isKorean ? '오늘' : 'Today';
  String get dashboardThisWeek => isKorean ? '이번 주' : 'This Week';
  String get dashboardThisMonth => isKorean ? '이번 달' : 'This Month';
  String get workoutCompleted => isKorean ? '운동 완료!' : 'Workout Done!';
  String get noWorkoutYet => isKorean ? '아직 운동 없음' : 'No workout yet';
  String setsCount(int count) => isKorean ? '$count세트' : '$count sets';
  String durationFormat(int minutes) => isKorean ? '$minutes분' : '${minutes}min';
  String workoutsCount(int count) => isKorean ? '$count회' : '$count times';
  String volumeFormat(String volume, String unit) => '$volume$unit';
  String get weeklyActivity => isKorean ? '주간 운동량' : 'Weekly Activity';
  String get noDataYet => isKorean ? '아직 기록이 없습니다' : 'No data yet';
  String dayAbbr(int weekday) {
    const koWeekdays = ['월', '화', '수', '목', '금', '토', '일'];
    const enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final index = (weekday - 1) % 7;
    return isKorean ? koWeekdays[index] : enWeekdays[index];
  }

  // Session Screen
  String workoutDateTitle(int month, int day) =>
      isKorean ? '$month월 $day일 운동' : 'Workout - $month/$day';
  String get finish => isKorean ? '종료' : 'Finish';
  String get addExercise => isKorean ? '운동 추가' : 'Add Exercise';
  String get addExercisePrompt => isKorean ? '운동을 추가하세요' : 'Add an exercise';
  String get finishWorkout => isKorean ? '운동 종료' : 'Finish Workout';
  String finishWorkoutMessage(int exercises, int sets) => isKorean
      ? '총 $exercises개 운동, $sets세트를 저장합니다.'
      : 'Saving $exercises exercises, $sets sets.';
  String get noSetsRecorded =>
      isKorean ? '기록된 세트가 없습니다. 그냥 종료하시겠습니까?' : 'No sets recorded. Exit anyway?';
  String setsSaved(int sets) =>
      isKorean ? '$sets세트가 저장되었습니다' : '$sets sets saved';
  String saveFailed(String error) =>
      isKorean ? '저장 실패: $error' : 'Save failed: $error';
  String get set => isKorean ? 'Set' : 'Set';
  String get reps => isKorean ? '회' : 'reps';

  // History Screen
  String get history => isKorean ? '기록' : 'History';
  String get selectDate => isKorean ? '날짜를 선택하세요' : 'Select a date';
  String dateFormat(int year, int month, int day) =>
      isKorean ? '$year년 $month월 $day일' : '$month/$day/$year';
  String get noWorkoutRecord =>
      isKorean ? '운동 기록이 없습니다' : 'No workout records';
  String get noSetRecord => isKorean ? '세트 기록이 없습니다' : 'No set records';
  String get unknownExercise => isKorean ? '알 수 없는 운동' : 'Unknown exercise';
  String get deleteRecord => isKorean ? '기록 삭제' : 'Delete Record';
  String deleteExerciseConfirm(String exerciseName) => isKorean
      ? '$exerciseName 기록을 삭제하시겠습니까?'
      : 'Delete $exerciseName records?';

  // Body Screen
  String get body => isKorean ? '바디' : 'Body';
  String get weightRecord => isKorean ? '체중 기록' : 'Weight Record';
  String get date => isKorean ? '날짜' : 'Date';
  String weightLabel(String unit) => isKorean ? '체중 ($unit)' : 'Weight ($unit)';
  String heightLabel(String unit) => isKorean ? '키 ($unit)' : 'Height ($unit)';
  String get height => isKorean ? '키' : 'Height';
  String get heightHelperText => isKorean ? 'BMI 계산을 위해 키를 입력하세요' : 'Enter height for BMI calculation';
  String get saveRecord => isKorean ? '기록 저장' : 'Save Record';
  String get weightTrend => isKorean ? '체중 추세' : 'Weight Trend';
  String get graphPlaceholder =>
      isKorean ? '기록이 쌓이면 그래프가 표시됩니다' : 'Graph will appear as records accumulate';
  String get enterWeight => isKorean ? '체중을 입력하세요' : 'Please enter weight';
  String get weightSaved => isKorean ? '체중이 기록되었습니다' : 'Weight recorded';
  String get bmiTitle => isKorean ? 'BMI 지수' : 'BMI Index';
  String get bmiDescription => isKorean ? '체질량지수 (Body Mass Index)' : 'Body Mass Index';
  String get recentRecords => isKorean ? '최근 기록' : 'Recent Records';

  // Progress Screen
  String get progress => isKorean ? '통계' : 'Progress';
  String get comingSoon => isKorean ? '준비 중입니다' : 'Coming soon';
  String get filterThisMonth => isKorean ? '이번 달' : 'This Month';
  String get filter3Months => isKorean ? '3개월' : '3 Months';
  String get filter6Months => isKorean ? '6개월' : '6 Months';
  String get filter12Months => isKorean ? '12개월' : '12 Months';
  String get filterAll => isKorean ? '전체' : 'All Time';
  String get totalStats => isKorean ? '운동 통계' : 'Workout Statistics';
  String get totalWorkouts => isKorean ? '운동 횟수' : 'Workouts';
  String get totalSetsLabel => isKorean ? '세트 수' : 'Sets';
  String get totalVolume => isKorean ? '총 볼륨' : 'Volume';
  String get exerciseProgress => isKorean ? '운동별 진행상황' : 'Exercise Progress';
  String get maxWeight => isKorean ? '최고 무게' : 'Max Weight';
  String get maxReps => isKorean ? '최고 횟수' : 'Max Reps';
  String get noExerciseData => isKorean ? '이 기간의 운동 데이터가 없습니다' : 'No exercise data for this period';
  String get weightProgress => isKorean ? '무게 진행' : 'Weight Progress';
  String get repsProgress => isKorean ? '횟수 진행' : 'Reps Progress';
  String changeFormat(String value) => isKorean ? '$value 변화' : '$value change';

  // Settings Screen
  String get settings => isKorean ? '설정' : 'Settings';
  String get weightUnit => isKorean ? '체중 단위' : 'Weight Unit';
  String get theme => isKorean ? '테마' : 'Theme';
  String get language => isKorean ? '언어' : 'Language';
  String get themeLight => isKorean ? '라이트' : 'Light';
  String get themeDark => isKorean ? '다크' : 'Dark';
  String get themeSystem => isKorean ? '시스템 설정' : 'System';
  String get korean => isKorean ? '한국어' : 'Korean';
  String get english => isKorean ? 'English' : 'English';
  String get manageExercises => isKorean ? '운동 종목 관리' : 'Manage Exercises';
  String get resetData => isKorean ? '데이터 초기화' : 'Reset Data';
  String get resetDataWarning => isKorean
      ? '모든 운동 기록과 체중 기록이 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'
      : 'All workout and weight records will be deleted.\nThis cannot be undone.';
  String get reset => isKorean ? '초기화' : 'Reset';
  String get dataReset => isKorean ? '데이터가 초기화되었습니다' : 'Data has been reset';
  String resetFailed(String error) =>
      isKorean ? '초기화 실패: $error' : 'Reset failed: $error';

  // Export
  String get exportData => isKorean ? '데이터 내보내기' : 'Export Data';
  String get exportDataDesc => isKorean ? 'CSV 파일로 내보내기' : 'Export as CSV files';
  String get exporting => isKorean ? '내보내는 중...' : 'Exporting...';
  String get noDataToExport => isKorean ? '내보낼 데이터가 없습니다' : 'No data to export';
  String exportFailed(String error) =>
      isKorean ? '내보내기 실패: $error' : 'Export failed: $error';

  // Import
  String get importData => isKorean ? '데이터 가져오기' : 'Import Data';
  String get importDataDesc => isKorean ? 'CSV 파일에서 가져오기' : 'Import from CSV files';
  String get importing => isKorean ? '가져오는 중...' : 'Importing...';
  String get importCancelled => isKorean ? '가져오기가 취소되었습니다' : 'Import cancelled';
  String get noDataImported => isKorean ? '가져올 데이터가 없습니다' : 'No data to import';
  String importSuccess(int sets, int bodyRecords, int exercises) {
    if (isKorean) {
      final parts = <String>[];
      if (sets > 0) parts.add('운동 $sets세트');
      if (bodyRecords > 0) parts.add('바디 기록 $bodyRecords개');
      if (exercises > 0) parts.add('새 운동 $exercises개');
      return '${parts.join(', ')} 가져옴';
    } else {
      final parts = <String>[];
      if (sets > 0) parts.add('$sets workout sets');
      if (bodyRecords > 0) parts.add('$bodyRecords body records');
      if (exercises > 0) parts.add('$exercises new exercises');
      return 'Imported ${parts.join(', ')}';
    }
  }
  String importFailed(String error) =>
      isKorean ? '가져오기 실패: $error' : 'Import failed: $error';
  String importWithErrors(int errorCount) =>
      isKorean ? '$errorCount개 오류 발생' : '$errorCount errors occurred';

  // Exercise Picker
  String get selectExercise => isKorean ? '운동 선택' : 'Select Exercise';
  String get searchExercise => isKorean ? '운동 검색' : 'Search exercise';
  String get noExercisesFound => isKorean ? '운동을 찾을 수 없습니다' : 'No exercises found';

  // Timer
  String get stopwatch => isKorean ? '스톱워치' : 'Stopwatch';
  String get timer => isKorean ? '타이머' : 'Timer';
  String get start => isKorean ? '시작' : 'Start';
  String get stop => isKorean ? '중지' : 'Stop';
  String get resetTimer => isKorean ? '리셋' : 'Reset';

  // Cardio
  String get durationMin => isKorean ? '시간(분)' : 'Min';
  String get distance => isKorean ? '거리' : 'Distance';
  String get totalDuration => isKorean ? '총 시간' : 'Total Time';
  String get totalDistance => isKorean ? '총 거리' : 'Total Distance';

  // Manage Exercises
  String get addExerciseTitle => isKorean ? '운동 추가' : 'Add Exercise';
  String get editExerciseTitle => isKorean ? '운동 수정' : 'Edit Exercise';
  String get exerciseName => isKorean ? '운동 이름' : 'Exercise Name';
  String get categoryLabel => isKorean ? '카테고리' : 'Category';
  String get muscleGroupLabel => isKorean ? '근육 부위 (선택)' : 'Muscle Group (optional)';
  String get enterExerciseName => isKorean ? '운동 이름을 입력하세요' : 'Please enter exercise name';
  String get exerciseAdded => isKorean ? '운동이 추가되었습니다' : 'Exercise added';
  String get exerciseUpdated => isKorean ? '운동이 수정되었습니다' : 'Exercise updated';
  String get exerciseDeleted => isKorean ? '운동이 삭제되었습니다' : 'Exercise deleted';
  String get deleteExerciseTitle => isKorean ? '운동 삭제' : 'Delete Exercise';
  String deleteExerciseMessage(String name) =>
      isKorean ? '$name을(를) 삭제하시겠습니까?' : 'Delete $name?';
  String get cannotDeleteDefault =>
      isKorean ? '기본 운동은 삭제할 수 없습니다' : 'Cannot delete default exercise';
  String get customExercise => isKorean ? '사용자 정의' : 'Custom';

  // About
  String get about => isKorean ? '앱 정보' : 'About';
  String get aboutDescription => isKorean
      ? '운동 기록과 바디 프로필을 간편하게 관리하세요'
      : 'Easily track your workouts and body profile';
  String get developer => isKorean ? '개발자' : 'Developer';
  String get contact => isKorean ? '문의' : 'Contact';
  String get version => isKorean ? '버전' : 'Version';

  // Update
  String get updateAvailable => isKorean ? '업데이트 가능' : 'Update Available';
  String updateMessage(String currentVersion, String availableVersion) => isKorean
      ? '새로운 버전($availableVersion)이 있습니다.\n현재 버전: $currentVersion'
      : 'A new version ($availableVersion) is available.\nCurrent version: $currentVersion';
  String get updateNow => isKorean ? '업데이트' : 'Update';
  String get updateLater => isKorean ? '나중에' : 'Later';
  String get updateIgnore => isKorean ? '이 버전 무시' : 'Ignore';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ko', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
