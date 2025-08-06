import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/baby.dart';
import '../models/baby_care.dart';

const String tablePerson = 'baby';
const String columnPersonId = '_id';
const String columnName = 'name';
const String columnSex = 'sex';
const String columnBirthdate = 'birthdate';
const String columnShow = 'show';

const String tableCare = 'babyCare';
const String columnCareId = '_id';
const String columnDate = 'date';
const String columnType = 'type';
const String columnMush = 'mush';

class DBProvider {
  static final DBProvider _singleton = DBProvider._internal();

  factory DBProvider() => _singleton;

  DBProvider._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'babyApp.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablePerson (
        $columnPersonId INTEGER PRIMARY KEY,
        $columnName TEXT,
        $columnSex INTEGER,
        $columnBirthdate TEXT,
        $columnShow INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCare (
        $columnCareId INTEGER PRIMARY KEY,
        $columnDate INTEGER,
        $columnType INTEGER,
        $columnMush TEXT
      )
    ''');
  }

  // Baby methods
  Future<Baby> insertPerson(Baby person) async {
    final dbClient = await db;
    person.id = await dbClient.insert(tablePerson, person.toMap());
    return person;
  }

  Future<List<Baby>?> queryAllPersons() async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(tablePerson);
    if (maps.isEmpty) return null;
    return maps.map((map) => Baby.fromMap(map)).toList();
  }

  Future<List<Baby>?> getVisiblePersons() async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      tablePerson,
      where: '$columnShow = ?',
      whereArgs: [1],
    );
    if (maps.isEmpty) return null;
    return maps.map((map) => Baby.fromMap(map)).toList();
  }

  Future<Baby?> getPersonById(int id) async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      tablePerson,
      where: '$columnPersonId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return Baby.fromMap(maps.first);
    return null;
  }

  Future<int> deletePerson(int id) async {
    final dbClient = await db;
    return await dbClient.delete(tablePerson, where: '$columnPersonId = ?', whereArgs: [id]);
  }

  Future<int> updatePerson(Baby person) async {
    final dbClient = await db;
    return await dbClient.update(
      tablePerson,
      person.toMap(),
      where: '$columnPersonId = ?',
      whereArgs: [person.id],
    );
  }

  // BabyCare methods
  Future<BabyCare> insertCare(BabyCare care) async {
    final dbClient = await db;
    care.id = await dbClient.insert(tableCare, care.toMap());
    return care;
  }

  Future<List<BabyCare>?> queryAllCare() async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(tableCare);
    if (maps.isEmpty) return null;
    return maps.map((map) => BabyCare.fromMap(map)).toList();
  }

  Future<BabyCare?> getCareById(int id) async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      tableCare,
      where: '$columnCareId = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) return BabyCare.fromMap(maps.first);
    return null;
  }

  Future<int> deleteCare(int id) async {
    final dbClient = await db;
    return await dbClient.delete(tableCare, where: '$columnCareId = ?', whereArgs: [id]);
  }

  Future<int> updateCare(BabyCare care) async {
    final dbClient = await db;
    return await dbClient.update(
      tableCare,
      care.toMap(),
      where: '$columnCareId = ?',
      whereArgs: [care.id],
    );
  }

  Future<List<BabyCare>> getCareByRange(int startMillis, int endMillis) async {
    final dbClient = await db;
    List<Map<String, dynamic>> maps = await dbClient.query(
      tableCare,
      where: '$columnDate >= ? AND $columnDate < ?',
      whereArgs: [startMillis, endMillis],
    );
    return maps.map((map) => BabyCare.fromMap(map)).toList();
  }

}
