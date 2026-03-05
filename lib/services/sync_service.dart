import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/env_config.dart';
import '../data/database.dart';
import '../models/family_member.dart';
import '../models/medication.dart';
import '../models/place.dart';
import '../models/shopping_item.dart';
import '../models/stock_movement.dart';

/// Synchronisation Supabase ↔ SQLite (mobile uniquement).
/// Sur web, les données sont lues/écrites directement via Supabase dans les repositories.
class SyncService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Supprime toutes les données locales de la famille donnée (déconnexion).
  static Future<void> clearLocalFamilyData(String? familyId) async {
    if (familyId == null || !EnvConfig.isConfigured || kIsWeb) return;
    final db = await AppDatabase.database;
    await db.transaction((txn) async {
      await txn.delete('stock_movements', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('shopping_items', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('user_allergies', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('medications', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('family_members', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('places', where: 'family_id = ?', whereArgs: [familyId]);
    });
  }

  /// Pull complet depuis Supabase vers SQLite pour la famille donnée.
  static Future<void> pull(String familyId) async {
    if (!EnvConfig.isConfigured || kIsWeb) return;
    final db = await AppDatabase.database;

    await db.transaction((txn) async {
      await txn.delete('stock_movements', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('shopping_items', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('user_allergies', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('medications', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('family_members', where: 'family_id = ?', whereArgs: [familyId]);
      await txn.delete('places', where: 'family_id = ?', whereArgs: [familyId]);
    });

    final hmList = await _client.from('household_members').select().eq('family_id', familyId).order('sort_order');
    final Map<String, int> remoteToLocalMember = {};
    for (final row in hmList) {
      final remoteId = row['id'] as String;
      final fm = FamilyMember(
        id: 0,
        name: row['name'] as String,
        sortOrder: row['sort_order'] as int? ?? 0,
      );
      final localId = await AppDatabase.insertFamilyMember(fm, familyId: familyId, remoteId: remoteId);
      remoteToLocalMember[remoteId] = localId;
    }

    final medList = await _client.from('medications').select().eq('family_id', familyId).order('nom');
    final Map<String, int> remoteToLocalMed = {};
    for (final row in medList) {
      final remoteId = row['id'] as String;
      final memberUuid = row['household_member_id'] as String?;
      final memberId = memberUuid != null ? remoteToLocalMember[memberUuid] : null;
      final m = Medication(
        id: null,
        serverId: remoteId,
        codeScanned: row['code_scanned'] as String? ?? '',
        nom: row['nom'] as String,
        quantite: row['quantite'] as int,
        unite: row['unite'] as String? ?? 'Plaquette',
        quantiteParUnite: row['quantite_par_unite'] as int?,
        datePeremption: row['date_peremption'] != null ? DateTime.parse(row['date_peremption'] as String) : null,
        lieu: row['lieu'] as String?,
        memberId: memberId,
        seuilAlerte: row['seuil_alerte'] as int? ?? 0,
        noticeUrl: row['notice_url'] as String?,
        photoPath: row['photo_path'] as String?,
      );
      final localId = await AppDatabase.insertMedication(m, familyId: familyId);
      remoteToLocalMed[remoteId] = localId;
    }

    final movList = await _client.from('stock_movements').select().eq('family_id', familyId);
    for (final row in movList) {
      final medUuid = row['medication_id'] as String?;
      final localMedId = medUuid != null ? remoteToLocalMed[medUuid] : null;
      if (localMedId == null) continue;
      final s = StockMovement(
        medicationId: localMedId,
        type: row['type'] == 'ajout' ? StockMovementType.ajout : StockMovementType.prise,
        quantite: row['quantite'] as int,
        date: DateTime.parse(row['date'] as String),
      );
      await AppDatabase.insertStockMovement(s, familyId: familyId, remoteId: row['id'] as String?);
    }

    final placesList = await _client.from('places').select().eq('family_id', familyId);
    for (final row in placesList) {
      await AppDatabase.insertPlace(Place(id: 0, name: row['name'] as String), familyId: familyId, remoteId: row['id'] as String?);
    }

    final shopList = await _client.from('shopping_items').select().eq('family_id', familyId);
    for (final row in shopList) {
      final medUuid = row['medication_id'] as String?;
      final localMedId = medUuid != null ? remoteToLocalMed[medUuid] : null;
      final item = ShoppingItem(
        medicationId: localMedId,
        label: row['label'] as String,
        checked: row['checked'] as bool? ?? false,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
      await AppDatabase.insertShoppingItem(item, familyId: familyId, remoteId: row['id'] as String?);
    }

    final allergiesList = await _client.from('user_allergies').select().eq('family_id', familyId);
    for (final row in allergiesList) {
      final memberUuid = row['household_member_id'] as String?;
      final memberId = memberUuid != null ? remoteToLocalMember[memberUuid] : null;
      await AppDatabase.insertAllergy(
        memberId: memberId,
        allergyText: row['allergy_text'] as String,
        familyId: familyId,
        remoteId: row['id'] as String?,
      );
    }
  }

  /// Push d'un médicament vers Supabase. Retourne l'UUID créé ou null.
  static Future<String?> pushMedication(Medication m, String familyId) async {
    if (!EnvConfig.isConfigured || kIsWeb) return m.serverId;
    final map = {
      'family_id': familyId,
      'code_scanned': m.codeScanned,
      'nom': m.nom,
      'quantite': m.quantite,
      'unite': m.unite,
      'quantite_par_unite': m.quantiteParUnite,
      'date_peremption': m.datePeremption?.toUtc().toIso8601String(),
      'lieu': m.lieu,
      'seuil_alerte': m.seuilAlerte,
      'notice_url': m.noticeUrl,
      'photo_path': m.photoPath,
    };
    if (m.serverId != null) {
      await _client.from('medications').update(map).eq('id', m.serverId!);
      return m.serverId;
    }
    final res = await _client.from('medications').insert(map).select('id').single();
    return res['id'] as String;
  }

  /// Push d'un mouvement de stock (mobile et web).
  static Future<void> pushStockMovement(StockMovement s, String medicationServerId, String familyId) async {
    if (!EnvConfig.isConfigured) return;
    await _client.from('stock_movements').insert({
      'family_id': familyId,
      'medication_id': medicationServerId,
      'type': s.type == StockMovementType.ajout ? 'ajout' : 'prise',
      'quantite': s.quantite,
      'date': s.date.toUtc().toIso8601String(),
    });
  }

  // --- Lecture Supabase (pour le web) ---

  static Future<List<Medication>> getMedicationsFromSupabase(String familyId) async {
    if (!EnvConfig.isConfigured) return [];
    final list = await _client.from('medications').select().eq('family_id', familyId).order('nom');
    return list.map((row) => _medicationFromRow(row)).toList();
  }

  static Medication _medicationFromRow(Map<String, dynamic> row) {
    return Medication(
      id: null,
      serverId: row['id'] as String,
      codeScanned: row['code_scanned'] as String? ?? '',
      nom: row['nom'] as String,
      quantite: row['quantite'] as int,
      unite: row['unite'] as String? ?? 'Plaquette',
      quantiteParUnite: row['quantite_par_unite'] as int?,
      datePeremption: row['date_peremption'] != null ? DateTime.parse(row['date_peremption'] as String) : null,
      lieu: row['lieu'] as String?,
      memberId: null,
      seuilAlerte: row['seuil_alerte'] as int? ?? 0,
      noticeUrl: row['notice_url'] as String?,
      photoPath: row['photo_path'] as String?,
    );
  }

  static Future<void> deleteMedicationFromSupabase(String? serverId) async {
    if (!EnvConfig.isConfigured || serverId == null) return;
    final id = serverId;
    await _client.from('stock_movements').delete().eq('medication_id', id);
    await _client.from('medications').delete().eq('id', id);
  }

  static Future<void> updateMedicationInSupabase(Medication m, String familyId) async {
    if (!EnvConfig.isConfigured || m.serverId == null) return;
    final id = m.serverId!;
    await _client.from('medications').update({
      'nom': m.nom,
      'quantite': m.quantite,
      'unite': m.unite,
      'quantite_par_unite': m.quantiteParUnite,
      'date_peremption': m.datePeremption?.toUtc().toIso8601String(),
      'lieu': m.lieu,
      'seuil_alerte': m.seuilAlerte,
      'notice_url': m.noticeUrl,
      'photo_path': m.photoPath,
    }).eq('id', id);
  }

  /// Prises (mouvements type 'prise') dans une plage de dates, pour les stats web.
  static Future<List<({String medicationId, int quantite})>> getPrisesInRangeFromSupabase(
    String familyId,
    DateTime start,
    DateTime end,
  ) async {
    if (!EnvConfig.isConfigured) return [];
    final startStr = start.toUtc().toIso8601String();
    final endStr = end.toUtc().toIso8601String();
    final list = await _client
        .from('stock_movements')
        .select('medication_id, quantite')
        .eq('family_id', familyId)
        .eq('type', 'prise')
        .gte('date', startStr)
        .lte('date', endStr);
    return list
        .map((row) => (
              medicationId: row['medication_id'] as String,
              quantite: row['quantite'] as int,
            ))
        .toList();
  }
}
