import '../../models/dose_log_model.dart';
import 'database_provider.dart';

/// Raw SQLite access for dose logs. Returns models, no domain logic.
class DoseLogLocalDataSource {
  final DatabaseProvider _provider;
  const DoseLogLocalDataSource(this._provider);

  Future<List<DoseLogModel>> getForPet(int petId, {int limit = 200}) async {
    final db = await _provider.database;
    final rows = await db.query('dose_logs',
        where: 'petId = ?',
        whereArgs: [petId],
        orderBy: 'givenAt DESC',
        limit: limit);
    return rows.map(DoseLogModel.fromMap).toList();
  }

  Future<int> insert(DoseLogModel log) async {
    final db = await _provider.database;
    return db.insert('dose_logs', log.toMap()..remove('id'));
  }

  Future<void> delete(int id) async {
    final db = await _provider.database;
    await db.delete('dose_logs', where: 'id = ?', whereArgs: [id]);
  }
}
