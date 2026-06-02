import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/body_records_table.dart';

part 'body_dao.g.dart';

@DriftAccessor(tables: [BodyRecords])
class BodyDao extends DatabaseAccessor<AppDatabase> with _$BodyDaoMixin {
  BodyDao(super.db);

  Future<List<BodyRecord>> getAllRecords() =>
      (select(bodyRecords)..orderBy([(r) => OrderingTerm.desc(r.date)])).get();

  Stream<List<BodyRecord>> watchAllRecords() =>
      (select(bodyRecords)..orderBy([(r) => OrderingTerm.desc(r.date)])).watch();

  Future<BodyRecord?> getRecordById(String id) =>
      (select(bodyRecords)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<BodyRecord?> getRecordByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(bodyRecords)
          ..where((r) =>
              r.date.isBiggerOrEqualValue(startOfDay) &
              r.date.isSmallerThanValue(endOfDay)))
        .getSingleOrNull();
  }

  Future<List<BodyRecord>> getRecordsInRange(DateTime start, DateTime end) =>
      (select(bodyRecords)
            ..where((r) =>
                r.date.isBiggerOrEqualValue(start) &
                r.date.isSmallerOrEqualValue(end))
            ..orderBy([(r) => OrderingTerm.asc(r.date)]))
          .get();

  Future<int> insertRecord(BodyRecordsCompanion record) =>
      into(bodyRecords).insert(record);

  Future<bool> updateRecord(BodyRecord record) =>
      update(bodyRecords).replace(record);

  Future<int> deleteRecord(String id) =>
      (delete(bodyRecords)..where((r) => r.id.equals(id))).go();
}
