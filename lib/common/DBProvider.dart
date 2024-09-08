import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/Persion.dart';

class DBProvider {

  //创建单例模式SQLite
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

  //初始化数据库
  Future<Database> _initDB() async {
    // 获取数据库文件的存储路径
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'demo.db');
    //定义了数据库的版本
    return await openDatabase(path,
      version: 1, onCreate: _onCreate);
  }

  //创建数据库表
  Future _onCreate(Database db, int version) async {
    return await db.execute('''
          CREATE TABLE $tablePerson (
            $columnId INTEGER PRIMARY KEY,
            $columnName TEXT,
            $columnSex TEXT,
            $columnAge INTEGER,
          ''');
  }

  // 插入人员信息
  Future<Person> insert(Person person) async {
    person.id = await _db!.insert(tablePerson, person.toMap());
    return person;
  }

  // 查找所有人员信息
  Future<List<Person>?> queryAll() async {
    List<Map> maps = await _db!.query(tablePerson, columns: [
      columnId,
      columnName,
      columnSex,
      columnAge
    ]);

    if (maps.isEmpty) {
      return null;
    }

    List<Person> books = [];
    for (int i = 0; i < maps.length; i++) {
      books.add(Person.fromMap(maps[i]));
    }

    return books;
  }

  // 根据ID查找个人信息
  Future<Person?> getBook(int id) async {
    List<Map> maps = await _db!.query(tablePerson,
        columns: [
          columnId,
          columnName,
          columnSex,
          columnAge
        ],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Person.fromMap(maps.first);
    }
    return null;
  }

  // 根据ID删除个人信息
  Future<int> delete(int id) async {
    return await _db!.delete(tablePerson, where: '$columnId = ?', whereArgs: [id]);
  }

  // 更新个人信息
  Future<int> update(Person person) async {
    return await _db!.update(tablePerson, person.toMap(),
        where: '$columnId = ?', whereArgs: [person.id]);
  }
}
