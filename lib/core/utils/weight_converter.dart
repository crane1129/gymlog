const double _kgToLbsRatio = 2.20462;

double kgToLbs(double kg) => kg * _kgToLbsRatio;

double lbsToKg(double lbs) => lbs / _kgToLbsRatio;

String formatWeight(double kg, {bool useLbs = false, int decimals = 1}) {
  final value = useLbs ? kgToLbs(kg) : kg;
  final unit = useLbs ? 'lbs' : 'kg';
  return '${value.toStringAsFixed(decimals)} $unit';
}

double calculate1RM(double weight, int reps) {
  if (reps <= 0) return weight;
  if (reps == 1) return weight;
  return weight * (1 + reps / 30);
}
