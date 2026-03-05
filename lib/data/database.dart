import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/family_member.dart';
import '../models/medication.dart';
import '../models/place.dart';
import '../models/stock_movement.dart';
import '../models/shopping_item.dart';

class AppDatabase {
  static const _dbName = 'medistock.db';
  static const _version = 7;

  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not available on web. Use Supabase for data.');
    }
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
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE medications ADD COLUMN family_id TEXT DEFAULT \'local\'');
      await db.execute('ALTER TABLE medications ADD COLUMN remote_id TEXT');
      await db.execute('ALTER TABLE family_members ADD COLUMN family_id TEXT DEFAULT \'local\'');
      await db.execute('ALTER TABLE family_members ADD COLUMN remote_id TEXT');
      await db.execute('ALTER TABLE places ADD COLUMN family_id TEXT DEFAULT \'local\'');
      await db.execute('ALTER TABLE places ADD COLUMN remote_id TEXT');
      await db.execute('ALTER TABLE stock_movements ADD COLUMN family_id TEXT DEFAULT \'local\'');
      await db.execute('ALTER TABLE stock_movements ADD COLUMN remote_id TEXT');
      await db.execute('ALTER TABLE shopping_items ADD COLUMN family_id TEXT DEFAULT \'local\'');
      await db.execute('ALTER TABLE shopping_items ADD COLUMN remote_id TEXT');
      await db.execute('ALTER TABLE user_allergies ADD COLUMN family_id TEXT DEFAULT \'local\'');
      await db.execute('ALTER TABLE user_allergies ADD COLUMN remote_id TEXT');
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        family_id TEXT DEFAULT 'local',
        remote_id TEXT,
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
        family_id TEXT DEFAULT 'local',
        remote_id TEXT,
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
        family_id TEXT DEFAULT 'local',
        remote_id TEXT,
        name TEXT NOT NULL,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        family_id TEXT DEFAULT 'local',
        remote_id TEXT,
        name TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE shopping_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        family_id TEXT DEFAULT 'local',
        remote_id TEXT,
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
        family_id TEXT DEFAULT 'local',
        remote_id TEXT,
        member_id INTEGER,
        allergy_text TEXT NOT NULL,
        FOREIGN KEY (member_id) REFERENCES family_members (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Medications ---
  static Future<int> insertMedication(Medication m, {String? familyId}) async {
    final db = await database;
    final map = m.toMap();
    map.remove('id');
    map['created_at'] = DateTime.now().toIso8601String();
    if (familyId != null) map['family_id'] = familyId;
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

  static Future<Medication?> getMedicationById(int id, {String? familyId}) async {
    final db = await database;
    final where = familyId != null ? 'id = ? AND family_id = ?' : 'id = ?';
    final whereArgs = familyId != null ? [id, familyId] : [id];
    final maps = await db.query('medications', where: where, whereArgs: whereArgs);
    if (maps.isEmpty) return null;
    return Medication.fromMap(maps.first);
  }

  static Future<Medication?> getMedicationByCode(String code, {String? familyId}) async {
    final db = await database;
    final where = familyId != null ? 'code_scanned = ? AND family_id = ?' : 'code_scanned = ?';
    final whereArgs = familyId != null ? [code, familyId] : [code];
    final maps = await db.query('medications', where: where, whereArgs: whereArgs);
    if (maps.isEmpty) return null;
    return Medication.fromMap(maps.first);
  }

  static Future<List<Medication>> getAllMedications({String? familyId}) async {
    final db = await database;
    final where = familyId != null ? 'family_id = ?' : null;
    final whereArgs = familyId != null ? [familyId] : null;
    final maps = await db.query(
      'medications',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'nom ASC',
    );
    return maps.map((m) => Medication.fromMap(m)).toList();
  }

  // --- Stock movements ---
  static Future<int> insertStockMovement(StockMovement s, {String? familyId, String? remoteId}) async {
    final db = await database;
    final map = s.toMap()..remove('id');
    if (familyId != null) map['family_id'] = familyId;
    if (remoteId != null) map['remote_id'] = remoteId;
    return db.insert('stock_movements', map);
  }

  static Future<void> deleteStockMovementsByFamilyId(String familyId) async {
    final db = await database;
    await db.delete('stock_movements', where: 'family_id = ?', whereArgs: [familyId]);
  }

  static Future<void> deleteMedicationsByFamilyId(String familyId) async {
    final db = await database;
    await db.delete('medications', where: 'family_id = ?', whereArgs: [familyId]);
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
  static Future<List<StockMovement>> getPrisesInRange(DateTime start, DateTime end, {String? familyId}) async {
    final db = await database;
    final startStr = DateTime(start.year, start.month, start.day).toIso8601String();
    final endStr = DateTime(end.year, end.month, end.day, 23, 59, 59).toIso8601String();
    final where = familyId != null
        ? "type = 'prise' AND date >= ? AND date <= ? AND family_id = ?"
        : "type = 'prise' AND date >= ? AND date <= ?";
    final whereArgs = familyId != null ? [startStr, endStr, familyId] : [startStr, endStr];
    final maps = await db.query(
      'stock_movements',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  // --- Family members ---
  static Future<List<FamilyMember>> getFamilyMembers({String? familyId}) async {
    final db = await database;
    final where = familyId != null ? 'family_id = ?' : null;
    final whereArgs = familyId != null ? [familyId] : null;
    final maps = await db.query(
      'family_members',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map((m) => FamilyMember.fromMap(m)).toList();
  }

  static Future<int> insertFamilyMember(FamilyMember fm, {String? familyId, String? remoteId}) async {
    final db = await database;
    final map = fm.toMap()..remove('id');
    if (familyId != null) map['family_id'] = familyId;
    if (remoteId != null) map['remote_id'] = remoteId;
    return db.insert('family_members', map);
  }

  static Future<void> deleteFamilyMembersByFamilyId(String familyId) async {
    final db = await database;
    await db.delete('family_members', where: 'family_id = ?', whereArgs: [familyId]);
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
  static Future<List<Place>> getPlaces({String? familyId}) async {
    final db = await database;
    final where = familyId != null ? 'family_id = ?' : null;
    final whereArgs = familyId != null ? [familyId] : null;
    final maps = await db.query(
      'places',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return maps.map((m) => Place.fromMap(m)).toList();
  }

  static Future<int> insertPlace(Place p, {String? familyId, String? remoteId}) async {
    final db = await database;
    final map = p.toMap()..remove('id');
    if (familyId != null) map['family_id'] = familyId;
    if (remoteId != null) map['remote_id'] = remoteId;
    return db.insert('places', map);
  }

  static Future<void> deletePlacesByFamilyId(String familyId) async {
    final db = await database;
    await db.delete('places', where: 'family_id = ?', whereArgs: [familyId]);
  }

  static Future<int> deletePlace(int id) async {
    final db = await database;
    return db.delete('places', where: 'id = ?', whereArgs: [id]);
  }

  // --- Shopping items ---
  static Future<List<ShoppingItem>> getShoppingItems({String? familyId}) async {
    final db = await database;
    final where = familyId != null ? 'family_id = ?' : null;
    final whereArgs = familyId != null ? [familyId] : null;
    final maps = await db.query(
      'shopping_items',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'checked ASC, created_at DESC',
    );
    return maps.map((m) => ShoppingItem.fromMap(m)).toList();
  }

  static Future<int> insertShoppingItem(ShoppingItem item, {String? familyId, String? remoteId}) async {
    final db = await database;
    final map = item.toMap();
    map.remove('id');
    if (familyId != null) map['family_id'] = familyId;
    if (remoteId != null) map['remote_id'] = remoteId;
    return db.insert('shopping_items', map);
  }

  static Future<void> deleteShoppingItemsByFamilyId(String familyId) async {
    final db = await database;
    await db.delete('shopping_items', where: 'family_id = ?', whereArgs: [familyId]);
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
  static Future<List<Map<String, dynamic>>> getAllergies({String? familyId}) async {
    final db = await database;
    final where = familyId != null ? 'family_id = ?' : null;
    final whereArgs = familyId != null ? [familyId] : null;
    return db.query(
      'user_allergies',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'id ASC',
    );
  }

  static Future<int> insertAllergy({int? memberId, required String allergyText, String? familyId, String? remoteId}) async {
    final db = await database;
    final map = {'member_id': memberId, 'allergy_text': allergyText};
    if (familyId != null) map['family_id'] = familyId;
    if (remoteId != null) map['remote_id'] = remoteId;
    return db.insert('user_allergies', map);
  }

  static Future<void> deleteAllergiesByFamilyId(String familyId) async {
    final db = await database;
    await db.delete('user_allergies', where: 'family_id = ?', whereArgs: [familyId]);
  }

  static Future<int> deleteAllergy(int id) async {
    final db = await database;
    return db.delete('user_allergies', where: 'id = ?', whereArgs: [id]);
  }
}
