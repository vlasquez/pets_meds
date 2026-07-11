import '../../models/weight_entry_model.dart';
import 'database_provider.dart';

/// Raw SQLite access for weight entries. Returns models, no domain logic.
class WeightLocalDataSource {
  final DatabaseProvider _provider;
  const WeightLocalDataSource(this._provider);

  Future<List<WeightEntryModel>> getForPet(int petId) async {
    final db = await _provider.database;
    final rows = await db.query('weight_entries',
        where: 'petId = ?', whereArgs: [petId], orderBy: 'measuredAt DESC');
    return rows.map(WeightEntryModel.fromMap).toList();
  }

  Future<int> insert(WeightEntryModel entry) async {
    final db = await _provider.database;
    return db.insert('weight_entries', entry.toMap()..remove('id'));
  }

  Future<void> delete(int id) async {
    final db = await _provider.database;
    await db.delete('weight_entries', where: 'id = ?', whereArgs: [id]);
  }
}
