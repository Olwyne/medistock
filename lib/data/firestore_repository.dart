import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/family_member.dart';
import '../models/medication.dart';
import '../models/place.dart';
import '../models/shopping_item.dart';
import '../models/stock_movement.dart';

/// Accès aux données du foyer dans Firestore.
/// Schéma : families/{familyId}/{medications,members,places,shoppingItems,allergies}
/// et families/{familyId}/medications/{medId}/movements/{movId}.
/// Remplace l'ancien AppDatabase (sqflite) + MedicationRepository + SyncService.
class FirestoreRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static DocumentReference<Map<String, dynamic>> _family(String familyId) =>
      _db.collection('families').doc(familyId);

  // --- Medications ---

  static Future<List<Medication>> getAllMedications(String familyId) async {
    final snap = await _family(familyId).collection('medications').orderBy('nom').get();
    return snap.docs.map((d) => Medication.fromFirestore(d.id, d.data())).toList();
  }

  static Future<Medication?> getMedicationById(String familyId, String id) async {
    final doc = await _family(familyId).collection('medications').doc(id).get();
    if (!doc.exists) return null;
    return Medication.fromFirestore(doc.id, doc.data()!);
  }

  static Future<Medication?> getMedicationByCode(String familyId, String code) async {
    final snap = await _family(familyId).collection('medications').where('codeScanned', isEqualTo: code).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return Medication.fromFirestore(snap.docs.first.id, snap.docs.first.data());
  }

  static Future<String> insertMedication(String familyId, Medication m) async {
    final ref = await _family(familyId).collection('medications').add(m.toFirestore());
    return ref.id;
  }

  static Future<void> updateMedication(String familyId, Medication m) async {
    if (m.id == null) return;
    await _family(familyId).collection('medications').doc(m.id).update(m.toFirestore());
  }

  static Future<void> deleteMedication(String familyId, String id) async {
    final medRef = _family(familyId).collection('medications').doc(id);
    final movements = await medRef.collection('movements').get();
    final batch = _db.batch();
    for (final mv in movements.docs) {
      batch.delete(mv.reference);
    }
    batch.delete(medRef);
    await batch.commit();
  }

  static Future<void> addStock(String familyId, String medicationId, double quantite) async {
    final medRef = _family(familyId).collection('medications').doc(medicationId);
    await medRef.update({'quantite': FieldValue.increment(quantite)});
    await insertStockMovement(
      familyId,
      medicationId,
      StockMovement(medicationId: medicationId, type: StockMovementType.ajout, quantite: quantite, date: DateTime.now()),
    );
  }

  static Future<void> takeStock(String familyId, String medicationId, double quantite) async {
    final medRef = _family(familyId).collection('medications').doc(medicationId);
    final snap = await medRef.get();
    final current = (snap.data()?['quantite'] as num? ?? 0).toDouble();
    final newQty = (current - quantite).clamp(0.0, current);
    await medRef.update({'quantite': newQty});
    await insertStockMovement(
      familyId,
      medicationId,
      StockMovement(medicationId: medicationId, type: StockMovementType.prise, quantite: quantite, date: DateTime.now()),
    );
  }

  // --- Stock movements ---

  static Future<void> insertStockMovement(String familyId, String medicationId, StockMovement s) async {
    await _family(familyId)
        .collection('medications')
        .doc(medicationId)
        .collection('movements')
        .add(s.toFirestore(familyId: familyId));
  }

  static Future<List<StockMovement>> getMovementsForMedication(String familyId, String medicationId, {int limit = 50}) async {
    final snap = await _family(familyId)
        .collection('medications')
        .doc(medicationId)
        .collection('movements')
        .orderBy('date', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => StockMovement.fromFirestore(d.id, medicationId, d.data())).toList();
  }

  /// Mouvements de type "prise" dans une plage de dates (pour les stats), via collectionGroup.
  static Future<List<StockMovement>> getPrisesInRange(String familyId, DateTime start, DateTime end) async {
    final startTs = Timestamp.fromDate(DateTime(start.year, start.month, start.day));
    final endTs = Timestamp.fromDate(DateTime(end.year, end.month, end.day, 23, 59, 59));
    final snap = await _db
        .collectionGroup('movements')
        .where('familyId', isEqualTo: familyId)
        .where('type', isEqualTo: 'prise')
        .where('date', isGreaterThanOrEqualTo: startTs)
        .where('date', isLessThanOrEqualTo: endTs)
        .get();
    return snap.docs.map((d) {
      final medicationId = d.reference.parent.parent!.id;
      return StockMovement.fromFirestore(d.id, medicationId, d.data());
    }).toList();
  }

  // --- Family members ---

  static Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    final snap = await _family(familyId).collection('members').orderBy('sortOrder').get();
    return snap.docs.map((d) => FamilyMember.fromFirestore(d.id, d.data())).toList();
  }

  static Future<String> insertFamilyMember(String familyId, FamilyMember fm) async {
    final ref = await _family(familyId).collection('members').add(fm.toFirestore());
    return ref.id;
  }

  static Future<void> deleteFamilyMember(String familyId, String id) async {
    await _family(familyId).collection('members').doc(id).delete();
  }

  // --- Places ---

  static Future<List<Place>> getPlaces(String familyId) async {
    final snap = await _family(familyId).collection('places').orderBy('name').get();
    return snap.docs.map((d) => Place.fromFirestore(d.id, d.data())).toList();
  }

  static Future<String> insertPlace(String familyId, Place p) async {
    final ref = await _family(familyId).collection('places').add(p.toFirestore());
    return ref.id;
  }

  static Future<void> deletePlace(String familyId, String id) async {
    await _family(familyId).collection('places').doc(id).delete();
  }

  // --- Shopping items ---

  static Future<List<ShoppingItem>> getShoppingItems(String familyId) async {
    final snap = await _family(familyId).collection('shoppingItems').orderBy('checked').orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => ShoppingItem.fromFirestore(d.id, d.data())).toList();
  }

  static Future<String> insertShoppingItem(String familyId, ShoppingItem item) async {
    final ref = await _family(familyId).collection('shoppingItems').add(item.toFirestore());
    return ref.id;
  }

  static Future<void> updateShoppingItem(String familyId, ShoppingItem item) async {
    if (item.id == null) return;
    await _family(familyId).collection('shoppingItems').doc(item.id).update(item.toFirestore());
  }

  static Future<void> deleteShoppingItem(String familyId, String id) async {
    await _family(familyId).collection('shoppingItems').doc(id).delete();
  }

  // --- Allergies (pour la vérification d'interaction) ---

  static Future<List<Map<String, dynamic>>> getAllergies(String familyId) async {
    final snap = await _family(familyId).collection('allergies').get();
    return snap.docs
        .map((d) => {
              'id': d.id,
              'member_id': d.data()['memberId'] as String?,
              'allergy_text': d.data()['allergyText'] as String? ?? '',
            })
        .toList();
  }

  static Future<String> insertAllergy(String familyId, {String? memberId, required String allergyText}) async {
    final ref = await _family(familyId).collection('allergies').add({
      'memberId': memberId,
      'allergyText': allergyText,
    });
    return ref.id;
  }

  static Future<void> deleteAllergy(String familyId, String id) async {
    await _family(familyId).collection('allergies').doc(id).delete();
  }
}
