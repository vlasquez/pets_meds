import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema.
class DatabaseProvider {
  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'pet_meds.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pets(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            species TEXT NOT NULL,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE medications(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            dosage TEXT NOT NULL,
            frequencyType TEXT NOT NULL,
            times TEXT NOT NULL,
            intervalDays INTEGER NOT NULL DEFAULT 1,
            startDate TEXT NOT NULL,
            endDate TEXT,
            active INTEGER NOT NULL DEFAULT 1,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE dose_logs(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            medicationId INTEGER NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
            petId INTEGER NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
            givenAt TEXT NOT NULL,
            note TEXT
          )
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }
}
