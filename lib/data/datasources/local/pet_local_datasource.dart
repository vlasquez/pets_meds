import '../../models/pet_model.dart';
import 'database_provider.dart';

/// Raw SQLite access for pets. Returns models, no domain logic.
class PetLocalDataSource {
  final DatabaseProvider _provider;
  const PetLocalDataSource(this._provider);

  Future<List<PetModel>> getPets() async {
    final db = await _provider.database;
    final rows = await db.query('pets', orderBy: 'name COLLATE NOCASE');
    return rows.map(PetModel.fromMap).toList();
  }

  Future<int> insert(PetModel pet) async {
    final db = await _provider.database;
    return db.insert('pets', pet.toMap()..remove('id'));
  }

  Future<void> update(PetModel pet) async {
    final db = await _provider.database;
    await db.update('pets', pet.toMap(), where: 'id = ?', whereArgs: [pet.id]);
  }

  Future<void> delete(int id) async {
    final db = await _provider.database;
    await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }
}
