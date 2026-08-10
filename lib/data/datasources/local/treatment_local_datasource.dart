import '../../models/treatment_model.dart';
import 'database_provider.dart';

/// Raw SQLite access for treatments. Joins the medication catalog so
/// rows carry `medicationName`. Returns models, no domain logic.
class TreatmentLocalDataSource {
  final DatabaseProvider _provider;
  const TreatmentLocalDataSource(this._provider);

  static const _select = '''
    SELECT t.*, m.name AS medicationName,
      (SELECT COUNT(*) FROM dose_logs d WHERE d.treatmentId = t.id)
        AS dosesGiven
    FROM treatments t
    JOIN medications m ON m.id = t.medicationId
  ''';

  Future<List<TreatmentModel>> getForPet(int petId) async {
    final db = await _provider.database;
    final rows = await db.rawQuery(
        '$_select WHERE t.petId = ? ORDER BY m.name COLLATE NOCASE', [petId]);
    return rows.map(TreatmentModel.fromMap).toList();
  }

  Future<List<TreatmentModel>> getAll() async {
    final db = await _provider.database;
    final rows =
        await db.rawQuery('$_select ORDER BY m.name COLLATE NOCASE');
    return rows.map(TreatmentModel.fromMap).toList();
  }

  Future<int> insert(TreatmentModel treatment) async {
    final db = await _provider.database;
    return db.insert('treatments', treatment.toMap()..remove('id'));
  }

  Future<void> update(TreatmentModel treatment) async {
    final db = await _provider.database;
    await db.update('treatments', treatment.toMap(),
        where: 'id = ?', whereArgs: [treatment.id]);
  }

  Future<void> delete(int id) async {
    final db = await _provider.database;
    await db.delete('treatments', where: 'id = ?', whereArgs: [id]);
  }
}
