import '../data/database.dart';
import '../models/medication.dart';
import '../models/stock_movement.dart';

class MedicationRepository {
  Future<List<Medication>> getAll({String? familyId}) =>
      AppDatabase.getAllMedications(familyId: familyId);

  Future<Medication?> getById(int id, {String? familyId}) =>
      AppDatabase.getMedicationById(id, familyId: familyId);

  Future<Medication?> getByCode(String code, {String? familyId}) =>
      AppDatabase.getMedicationByCode(code, familyId: familyId);

  Future<int> insert(Medication m, {String? familyId}) =>
      AppDatabase.insertMedication(m, familyId: familyId);

  Future<int> update(Medication m) => AppDatabase.updateMedication(m);

  Future<int> delete(int id) => AppDatabase.deleteMedication(id);

  /// Ajoute de la quantité au stock et enregistre le mouvement.
  Future<void> addStock(int medicationId, int quantite, {String? familyId}) async {
    final m = await AppDatabase.getMedicationById(medicationId, familyId: familyId);
    if (m == null) return;
    await AppDatabase.updateMedication(m.copyWith(quantite: m.quantite + quantite));
    await AppDatabase.insertStockMovement(StockMovement(
      medicationId: medicationId,
      type: StockMovementType.ajout,
      quantite: quantite,
      date: DateTime.now(),
    ), familyId: familyId);
  }

  /// Retire de la quantité (prise) et enregistre le mouvement.
  Future<void> takeStock(int medicationId, int quantite, {String? familyId}) async {
    final m = await AppDatabase.getMedicationById(medicationId, familyId: familyId);
    if (m == null) return;
    final newQty = (m.quantite - quantite).clamp(0, m.quantite);
    await AppDatabase.updateMedication(m.copyWith(quantite: newQty));
    await AppDatabase.insertStockMovement(StockMovement(
      medicationId: medicationId,
      type: StockMovementType.prise,
      quantite: quantite,
      date: DateTime.now(),
    ), familyId: familyId);
  }

  Future<List<StockMovement>> getMovements(int medicationId, {int limit = 50}) =>
      AppDatabase.getMovementsForMedication(medicationId, limit: limit);
}
