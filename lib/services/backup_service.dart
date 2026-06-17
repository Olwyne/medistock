import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'reminder_service.dart';

const _backupApp = 'medistock';
const _backupVersion = 2;

const _keyFirstDayOfWeek = 'first_day_of_week';
const _keyScanSound = 'scan_sound';
const _keyOnboardingDone = 'onboarding_done';
const _keyLocale = 'locale';
const _reminderPrefix = 'reminder_';

/// Sauvegarde / restauration du foyer courant (Firestore) en JSON.
class BackupService {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _family(String familyId) => _db.collection('families').doc(familyId);

  static Future<List<Map<String, dynamic>>> _dump(String familyId, String collection) async {
    final snap = await _family(familyId).collection(collection).get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Exporte les données du foyer vers un fichier JSON. Retourne le chemin du fichier.
  static Future<String> exportToFile(String familyId) async {
    final prefs = await SharedPreferences.getInstance();

    final medications = await _dump(familyId, 'medications');
    final familyMembers = await _dump(familyId, 'members');
    final places = await _dump(familyId, 'places');
    final shoppingItems = await _dump(familyId, 'shoppingItems');
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
      'family_id': familyId,
      'medications': medications.map(_serialize).toList(),
      'family_members': familyMembers.map(_serialize).toList(),
      'places': places.map(_serialize).toList(),
      'shopping_items': shoppingItems.map(_serialize).toList(),
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

  /// Convertit les Timestamp Firestore en chaînes ISO8601 pour la sérialisation JSON.
  static Map<String, dynamic> _serialize(Map<String, dynamic> m) {
    return m.map((k, v) => MapEntry(k, v is Timestamp ? v.toDate().toIso8601String() : v));
  }

  /// Valide la structure du JSON de sauvegarde. Retourne null si valide, message d'erreur sinon.
  static String? validateBackup(Map<String, dynamic> json) {
    if (json['app'] != _backupApp) return 'Invalid backup: wrong app';
    if (json['version'] != _backupVersion) return 'Invalid backup: wrong version';
    if (json['medications'] is! List) return 'Invalid backup: missing medications';
    return null;
  }

  /// Importe depuis un JSON de sauvegarde. Remplace toutes les données actuelles du foyer.
  static Future<void> importFromMap(String familyId, Map<String, dynamic> json) async {
    final err = validateBackup(json);
    if (err != null) throw Exception(err);

    final prefs = await SharedPreferences.getInstance();

    final medicationsList = (json['medications'] as List).cast<Map<String, dynamic>>();
    final familyList = (json['family_members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final placesList = (json['places'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final shoppingList = (json['shopping_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final settings = (json['settings'] as Map?)?.cast<String, dynamic>() ?? {};
    final locale = json['locale'] as String? ?? '';
    final reminders = (json['reminders'] as Map?)?.cast<String, String>() ?? {};

    final famRef = _family(familyId);

    for (final coll in ['medications', 'members', 'places', 'shoppingItems']) {
      final existing = await famRef.collection(coll).get();
      for (final d in existing.docs) {
        await d.reference.delete();
      }
    }

    final oldToNewMedicationId = <String, String>{};
    for (final m in medicationsList) {
      final map = Map<String, dynamic>.from(m);
      final oldId = map.remove('id') as String?;
      final ref = await famRef.collection('medications').add(map);
      if (oldId != null) oldToNewMedicationId[oldId] = ref.id;
    }

    for (final fm in familyList) {
      final map = Map<String, dynamic>.from(fm)..remove('id');
      await famRef.collection('members').add(map);
    }

    for (final p in placesList) {
      final map = Map<String, dynamic>.from(p)..remove('id');
      await famRef.collection('places').add(map);
    }

    for (final si in shoppingList) {
      final map = Map<String, dynamic>.from(si)..remove('id');
      final oldMid = map['medicationId'] as String?;
      map['medicationId'] = oldMid != null ? oldToNewMedicationId[oldMid] : null;
      await famRef.collection('shoppingItems').add(map);
    }

    await prefs.setInt(_keyFirstDayOfWeek, settings[_keyFirstDayOfWeek] as int? ?? 1);
    await prefs.setBool(_keyScanSound, settings[_keyScanSound] as bool? ?? true);
    await prefs.setBool(_keyOnboardingDone, settings[_keyOnboardingDone] as bool? ?? false);
    await prefs.setString(_keyLocale, locale);

    // Réapplique les rappels en remappant ancien id médicament -> nouveau.
    for (final e in reminders.entries) {
      final oldId = e.key;
      final newId = oldToNewMedicationId[oldId];
      if (newId != null) await prefs.setString('$_reminderPrefix$newId', e.value);
    }
  }
}
