import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/family_member.dart';
import '../models/medication.dart';
import '../models/place.dart';
import '../models/stock_movement.dart';
import '../models/shopping_item.dart';

class AppDatabase {
  static const _dbName = 'medistock.db';
  static const _version = 6;

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE medications ADD COLUMN quantite_par_unite INTEGER');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE medications ADD COLUMN member_id INTEGER');
      await db.execute('''
        CREATE TABLE family_members (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          sort_order INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE places (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE medications ADD COLUMN photo_path TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE shopping_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          medication_id INTEGER,
          label TEXT NOT NULL,
          checked INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE SET NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE user_allergies (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          member_id INTEGER,
          allergy_text TEXT NOT NULL,
          FOREIGN KEY (member_id) REFERENCES family_members (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code_scanned TEXT NOT NULL,
        nom TEXT NOT NULL,
        quantite INTEGER NOT NULL,
        unite TEXT NOT NULL DEFAULT 'Plaquette',
        quantite_par_unite INTEGER,
        date_peremption TEXT,
        lieu TEXT,
        member_id INTEGER,
        seuil_alerte INTEGER NOT NULL DEFAULT 0,
        notice_url TEXT,
        photo_path TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantite INTEGER NOT NULL,
        date TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_medications_code ON medications(code_scanned)');
    await db.execute('CREATE INDEX idx_stock_movements_medication ON stock_movements(medication_id)');
    await db.execute('''
      CREATE TABLE family_members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE shopping_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medication_id INTEGER,
        label TEXT NOT NULL,
        checked INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE user_allergies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        member_id INTEGER,
        allergy_text TEXT NOT NULL,
        FOREIGN KEY (member_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Medications ---
  static Future<int> insertMedication(Medication m) async {
    final db = await database;
    final map = m.toMap();
    map.remove('id');
    map['created_at'] = DateTime.now().toIso8601String();
    return db.insert('medications', map);
  }

  static Future<int> updateMedication(Medication m) async {
    final db = await database;
    if (m.id == null) return 0;
    return db.update('medications', m.toMap(), where: 'id = ?', whereArgs: [m.id]);
  }

  static Future<int> deleteMedication(int id) async {
    final db = await database;
    await db.delete('stock_movements', where: 'medication_id = ?', whereArgs: [id]);
    return db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Medication?> getMedicationById(int id) async {
    final db = await database;
    final maps = await db.query('medications', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Medication.fromMap(maps.first);
  }

  static Future<Medication?> getMedicationByCode(String code) async {
    final db = await database;
    final maps = await db.query('medications', where: 'code_scanned = ?', whereArgs: [code]);
    if (maps.isEmpty) return null;
    return Medication.fromMap(maps.first);
  }

  static Future<List<Medication>> getAllMedications() async {
    final db = await database;
    final maps = await db.query('medications', orderBy: 'nom ASC');
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  // --- Stock movements ---
  static Future<int> insertStockMovement(StockMovement s) async {
    final db = await database;
    return db.insert('stock_movements', s.toMap()..remove('id'));
  }

  static Future<List<StockMovement>> getMovementsForMedication(int medicationId, {int limit = 50}) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'medication_id = ?',
      whereArgs: [medicationId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  /// Returns all "prise" movements in the given date range (inclusive).
  static Future<List<StockMovement>> getPrisesInRange(DateTime start, DateTime end) async {
    final db = await database;
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();
    final maps = await db.query(
      'stock_movements',
      where: "type = 'prise' AND date >= ? AND date <= ?",
      whereArgs: [startStr, endStr],
      orderBy: 'date DESC',
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  // --- Family members ---
  static Future<List<FamilyMember>> getFamilyMembers() async {
    final db = await database;
    final maps = await db.query('family_members', orderBy: 'sort_order ASC, id ASC');
    return maps.map((m) => FamilyMember.fromMap(m)).toList();
  }

  static Future<int> insertFamilyMember(FamilyMember fm) async {
    final db = await database;
    return db.insert('family_members', fm.toMap()..remove('id'));
  }

  static Future<int> deleteFamilyMember(int id) async {
    final db = await database;
    return db.delete('family_members', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateFamilyMember(FamilyMember fm) async {
    final db = await database;
    return db.update('family_members', fm.toMap(), where: 'id = ?', whereArgs: [fm.id]);
  }

  // --- Places ---
  static Future<List<Place>> getPlaces() async {
    final db = await database;
    final maps = await db.query('places', orderBy: 'name ASC');
    return maps.map((m) => Place.fromMap(m)).toList();
  }

  static Future<int> insertPlace(Place p) async {
    final db = await database;
    return db.insert('places', p.toMap()..remove('id'));
  }

  static Future<int> deletePlace(int id) async {
    final db = await database;
    return db.delete('places', where: 'id = ?', whereArgs: [id]);
  }

  // --- Shopping items ---
  static Future<List<ShoppingItem>> getShoppingItems() async {
    final db = await database;
    final maps = await db.query('shopping_items', orderBy: 'checked ASC, created_at DESC');
    return maps.map((m) => ShoppingItem.fromMap(m)).toList();
  }

  static Future<int> insertShoppingItem(ShoppingItem item) async {
    final db = await database;
    final map = item.toMap();
    map.remove('id');
    return db.insert('shopping_items', map);
  }

  static Future<int> updateShoppingItem(ShoppingItem item) async {
    final db = await database;
    if (item.id == null) return 0;
    return db.update('shopping_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  static Future<int> deleteShoppingItem(int id) async {
    final db = await database;
    return db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  // --- User allergies (for interaction check) ---
  static Future<List<Map<String, dynamic>>> getAllergies() async {
    final db = await database;
    return db.query('user_allergies', orderBy: 'id ASC');
  }

  static Future<int> insertAllergy({int? memberId, required String allergyText}) async {
    final db = await database;
    return db.insert('user_allergies', {'member_id': memberId, 'allergy_text': allergyText});
  }

  static Future<int> deleteAllergy(int id) async {
    final db = await database;
    return db.delete('user_allergies', where: 'id = ?', whereArgs: [id]);
  }
}
