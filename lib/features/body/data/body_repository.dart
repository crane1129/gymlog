import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../workout/data/workout_repository.dart';

final bodyRepositoryProvider = Provider<BodyRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return BodyRepository(db);
});

class BodyRepository {
  final AppDatabase _db;
  static const _uuid = Uuid();

  BodyRepository(this._db);

  Stream<List<BodyRecord>> watchAllRecords() {
    return (_db.select(_db.bodyRecords)
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .watch();
  }

  Future<List<BodyRecord>> getAllRecords() {
    return (_db.select(_db.bodyRecords)
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .get();
  }

  Future<List<BodyRecord>> getRecentRecords(int limit) {
    return (_db.select(_db.bodyRecords)
          ..orderBy([(r) => OrderingTerm.desc(r.date)])
          ..limit(limit))
        .get();
  }

  Future<BodyRecord?> getRecordByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (_db.select(_db.bodyRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(startOfDay) &
              r.date.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  Future<void> addOrUpdateRecord({
    required DateTime date,
    required double weightKg,
  }) async {
    final existing = await getRecordByDate(date);
    final now = DateTime.now();

    if (existing != null) {
      await (_db.update(_db.bodyRecords)
            ..where((r) => r.id.equals(existing.id)))
          .write(BodyRecordsCompanion(
        weightKg: Value(weightKg),
        updatedAt: Value(now),
      ));
    } else {
      await _db.into(_db.bodyRecords).insert(
            BodyRecordsCompanion.insert(
              id: _uuid.v4(),
              date: date,
              weightKg: weightKg,
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  Future<void> deleteRecord(String id) async {
    await (_db.delete(_db.bodyRecords)..where((r) => r.id.equals(id))).go();
  }
}
