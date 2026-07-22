import '../../models/medication_model.dart';
import 'database_provider.dart';

/// Raw SQLite access for the medication catalog.
/// Returns models, no domain logic.
class MedicationLocalDataSource {
  final DatabaseProvider _provider;
  const MedicationLocalDataSource(this._provider);

  Future<List<MedicationModel>> getAll() async {
    final db = await _provider.database;
    final rows =
        await db.query('medications', orderBy: 'name COLLATE NOCASE');
    return rows.map(MedicationModel.fromMap).toList();
  }

  Future<int> insert(MedicationModel med) async {
    final db = await _provider.database;
    return db.insert('medications', med.toMap()..remove('id'));
  }

  Future<void> update(MedicationModel med) async {
    final db = await _provider.database;
    await db.update('medications', med.toMap(),
        where: 'id = ?', whereArgs: [med.id]);
  }

  Future<void> delete(int id) async {
    final db = await _provider.database;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }
}
