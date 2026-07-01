import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/food_item.dart';

/// sqflite 기반 로컬 데이터베이스. 모든 기록은 기기 내부에만 저장된다.
class FoodDatabase {
  FoodDatabase._();
  static final FoodDatabase instance = FoodDatabase._();

  static const _dbName = 'fridge.db';
  static const _table = 'food_items';

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            category TEXT NOT NULL,
            storage TEXT NOT NULL,
            expiryDate INTEGER NOT NULL,
            addedDate INTEGER NOT NULL,
            quantity INTEGER NOT NULL DEFAULT 1,
            memo TEXT NOT NULL DEFAULT '',
            barcode TEXT,
            imagePath TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_food_expiry ON $_table (expiryDate ASC)',
        );
      },
    );
  }

  Future<FoodItem> insert(FoodItem item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    final id = await db.insert(_table, map);
    return item.copyWith(id: id);
  }

  Future<void> update(FoodItem item) async {
    if (item.id == null) return;
    final db = await database;
    await db.update(_table, item.toMap(),
        where: 'id = ?', whereArgs: [item.id]);
  }

  /// 유통기한이 임박한 순(오름차순)으로 전체 조회.
  Future<List<FoodItem>> getAll() async {
    final db = await database;
    final rows = await db.query(_table, orderBy: 'expiryDate ASC');
    return rows.map(FoodItem.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await database;
    await db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }
}
