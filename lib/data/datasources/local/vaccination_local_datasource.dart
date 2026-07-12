import '../../models/vaccination_model.dart';
import 'database_provider.dart';

/// Raw SQLite access for vaccinations. Returns models, no domain logic.
class VaccinationLocalDataSource {
  final DatabaseProvider _provider;
  const VaccinationLocalDataSource(this._provider);

  Future<List<VaccinationModel>> getForPet(int petId) async {
    final db = await _provider.database;
    final rows = await db.query('vaccinations',
        where: 'petId = ?', whereArgs: [petId], orderBy: 'appliedAt DESC');
    return rows.map(VaccinationModel.fromMap).toList();
  }

  Future<int> insert(VaccinationModel vaccination) async {
    final db = await _provider.database;
    return db.insert('vaccinations', vaccination.toMap()..remove('id'));
  }

  Future<void> delete(int id) async {
    final db = await _provider.database;
    await db.delete('vaccinations', where: 'id = ?', whereArgs: [id]);
  }
}
