import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database.dart';
import 'reminder_service.dart';

const _backupApp = 'medistock';
const _backupVersion = 1;

const _keyFirstDayOfWeek = 'first_day_of_week';
const _keyScanSound = 'scan_sound';
const _keyOnboardingDone = 'onboarding_done';
const _keyLocale = 'locale';
const _reminderPrefix = 'reminder_';

class BackupService {
  /// Exports all data to a JSON file. Returns the file path.
  static Future<String> exportToFile() async {
    final db = await AppDatabase.database;
    final prefs = await SharedPreferences.getInstance();

    final medications = await db.query('medications', orderBy: 'id ASC');
    final movements = await db.query('stock_movements');
    final familyMembers = await db.query('family_members');
    final places = await db.query('places');
    final shoppingItems = await db.query('shopping_items');
    final reminders = await ReminderService.getAllReminders();

    final settings = {
      _keyFirstDayOfWeek: prefs.getInt(_keyFirstDayOfWeek) ?? 1,
      _keyScanSound: prefs.getBool(_keyScanSound) ?? true,
      _keyOnboardingDone: prefs.getBool(_keyOnboardingDone) ?? false,
    };
    final locale = prefs.getString(_keyLocale) ?? '';

    final payload = {
      'app': _backupApp,
      'version': _backupVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'medications': medications,
      'stock_movements': movements,
      'family_members': familyMembers,
      'places': places,
      'shopping_items': shoppingItems,
      'settings': settings,
      'locale': locale,
      'reminders': reminders,
    };

    final dir = await getApplicationDocumentsDirectory();
    final name = 'medistock_backup_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    return file.path;
  }

  /// Validates backup JSON structure. Returns null if valid, error message otherwise.
  static String? validateBackup(Map<String, dynamic> json) {
    if (json['app'] != _backupApp) return 'Invalid backup: wrong app';
    if (json['version'] != _backupVersion) return 'Invalid backup: wrong version';
    if (json['medications'] is! List) return 'Invalid backup: missing medications';
    return null;
  }

  /// Imports from a backup JSON map. Replaces all current data.
  static Future<void> importFromMap(Map<String, dynamic> json) async {
    final err = validateBackup(json);
    if (err != null) throw Exception(err);

    final db = await AppDatabase.database;
    final prefs = await SharedPreferences.getInstance();

    final medicationsList = json['medications'] as List;
    final movementsList = (json['stock_movements'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final familyList = (json['family_members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final placesList = (json['places'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final shoppingList = (json['shopping_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final settings = (json['settings'] as Map?)?.cast<String, dynamic>() ?? {};
    final locale = json['locale'] as String? ?? '';
    final reminders = (json['reminders'] as Map?)?.cast<String, String>() ?? {};

    await db.transaction((txn) async {
      await txn.delete('shopping_items');
      await txn.delete('stock_movements');
      await txn.delete('medications');
      await txn.delete('family_members');
      await txn.delete('places');

      final oldToNewMedicationId = <int, int>{};
      for (final m in medicationsList) {
        final map = Map<String, dynamic>.from(m as Map);
        final oldId = map['id'] as int?;
        map.remove('id');
        map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
        final newId = await txn.insert('medications', map);
        if (oldId != null) oldToNewMedicationId[oldId] = newId;
      }

      for (final mov in movementsList) {
        final oldMid = mov['medication_id'] as int?;
        final newMid = oldToNewMedicationId[oldMid];
        if (newMid == null) continue;
        await txn.insert('stock_movements', {
          'medication_id': newMid,
          'type': mov['type'],
          'quantite': mov['quantite'],
          'date': mov['date'],
        });
      }

      for (final fm in familyList) {
        final map = Map<String, dynamic>.from(fm);
        map.remove('id');
        await txn.insert('family_members', map);
      }

      for (final p in placesList) {
        final map = Map<String, dynamic>.from(p);
        map.remove('id');
        await txn.insert('places', map);
      }

      for (final si in shoppingList) {
        final map = Map<String, dynamic>.from(si);
        map.remove('id');
        final oldMid = map['medication_id'] as int?;
        map['medication_id'] = oldToNewMedicationId[oldMid];
        map['created_at'] = map['created_at'] ?? DateTime.now().toIso8601String();
        await txn.insert('shopping_items', map);
      }
    });

    await prefs.setInt(_keyFirstDayOfWeek, settings[_keyFirstDayOfWeek] as int? ?? 1);
    await prefs.setBool(_keyScanSound, settings[_keyScanSound] as bool? ?? true);
    await prefs.setBool(_keyOnboardingDone, settings[_keyOnboardingDone] as bool? ?? false);
    await prefs.setString(_keyLocale, locale);

    // Re-apply reminders: oldId -> newId from insert order.
    final oldToNew = <int, int>{};
    final medsOrder = medicationsList;
    final newIds = await db.query('medications', orderBy: 'id ASC', columns: ['id']);
    for (var i = 0; i < medsOrder.length && i < newIds.length; i++) {
      final oldId = (medsOrder[i] as Map)['id'] as int?;
      if (oldId != null) oldToNew[oldId] = newIds[i]['id'] as int;
    }
    for (final e in reminders.entries) {
      final oldId = int.tryParse(e.key);
      if (oldId == null) continue;
      final newId = oldToNew[oldId];
      if (newId != null) await prefs.setString('$_reminderPrefix$newId', e.value);
    }
  }
}
