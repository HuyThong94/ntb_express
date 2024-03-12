import 'dart:io';
import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class NotificationGroup {
  static final String all = 'all';
  static final String order = 'order';
}

class TableName {
  static final notification = 'notification';
  static final notificationDetail = 'notification_detail';
}

class DatabaseHelper {
  static final _dbName = 'ntb_express.db';
  static final _dbVersion = 1;
  static final _tables = [
    '''
    CREATE TABLE ${TableName.notification} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer_id TEXT NOT NULL,
      notification_group TEXT NULL,
      order_id TEXT NULL UNIQUE,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      read INTEGER NOT NULL DEFAULT 0,
      insert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    ''',
    '''
    CREATE TABLE ${TableName.notificationDetail} (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id TEXT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      insert_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    '''
  ];

  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static late Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    for (var script in _tables) {
      await db.execute(script);
    }
  }

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> insert(String table, Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Map<String, dynamic>>> queryAllRows(String table) async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // All of the methods (insert, query, update, delete) can also be done using
  // raw SQL commands. This method uses a raw query to give the row count.
  Future<int?> queryRowCount(String table) async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'));
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> update(
      String table, String columnId, Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> delete(String table, String columnId, dynamic id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}
