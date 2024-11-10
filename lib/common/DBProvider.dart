import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/Baby.dart';
import '../models/BabyCare.dart';


class DBProvider {
  // Singleton pattern for SQLite
  static final DBProvider _singleton = DBProvider._internal();

  factory DBProvider() {
    return _singleton;
  }

  DBProvider._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDB();
    return _db!;
  }

  // Initialize the database with both tables
  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'babyApp.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  // Create both tables in the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePerson (
        $columnPersonId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnSex TEXT,
        $columnBirthdate TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCare (
        $columnCareId INTEGER PRIMARY KEY,
        $columnMilk INTEGER,
        $columnWater INTEGER,
        $columnDefecate INTEGER
      )
    ''');
  }

  // CRUD methods for tablePerson

  // Insert a Baby record into tablePerson
  Future<Baby> insertPerson(Baby person) async {
    final dbClient = await db;
    person.id = await dbClient.insert(tablePerson, person.toMap());
    return person;
  }

  // Query all Baby records from tablePerson
  Future<List<Baby>?> queryAllPersons() async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(tablePerson, columns: [
      columnPersonId,
      columnName,
      columnSex,
      columnBirthdate
    ]);

    if (maps.isEmpty) {
      return null;
    }

    return maps.map((map) => Baby.fromMap(map)).toList();
  }

  // Query a Baby record by ID from tablePerson
  Future<Baby?> getPersonById(int id) async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      tablePerson,
      columns: [
        columnPersonId,
        columnName,
        columnSex,
        columnBirthdate
      ],
      where: '$columnPersonId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Baby.fromMap(maps.first);
    }
    return null;
  }

  // Delete a Baby record by ID from tablePerson
  Future<int> deletePerson(int id) async {
    final dbClient = await db;
    return await dbClient.delete(tablePerson, where: '$columnPersonId = ?', whereArgs: [id]);
  }

  // Update a Baby record in tablePerson
  Future<int> updatePerson(Baby person) async {
    final dbClient = await db;
    return await dbClient.update(
      tablePerson,
      person.toMap(),
      where: '$columnPersonId = ?',
      whereArgs: [person.id],
    );
  }

  // CRUD methods for tableCare

  // Insert a BabyCare record into tableCare
  Future<BabyCare> insertCare(BabyCare care) async {
    final dbClient = await db;
    care.id = await dbClient.insert(tableCare, care.toMap());
    return care;
  }

  // Query all BabyCare records from tableCare
  Future<List<BabyCare>?> queryAllCare() async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(tableCare, columns: [
      columnCareId,
      columnMilk,
      columnWater,
      columnDefecate
    ]);

    if (maps.isEmpty) {
      return null;
    }

    return maps.map((map) => BabyCare.fromMap(map)).toList();
  }

  // Query a BabyCare record by ID from tableCare
  Future<BabyCare?> getCareById(int id) async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      tableCare,
      columns: [
        columnCareId,
        columnMilk,
        columnWater,
        columnDefecate
      ],
      where: '$columnCareId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return BabyCare.fromMap(maps.first);
    }
    return null;
  }

  // Delete a BabyCare record by ID from tableCare
  Future<int> deleteCare(int id) async {
    final dbClient = await db;
    return await dbClient.delete(tableCare, where: '$columnCareId = ?', whereArgs: [id]);
  }

  // Update a BabyCare record in tableCare
  Future<int> updateCare(BabyCare care) async {
    final dbClient = await db;
    return await dbClient.update(
      tableCare,
      care.toMap(),
      where: '$columnCareId = ?',
      whereArgs: [care.id],
    );
  }
}
