import '../data/database.dart';
import '../models/medication.dart';
import '../models/stock_movement.dart';

class MedicationRepository {
  Future<List<Medication>> getAll() => AppDatabase.getAllMedications();

  Future<Medication?> getById(int id) => AppDatabase.getMedicationById(id);

  Future<Medication?> getByCode(String code) => AppDatabase.getMedicationByCode(code);

  Future<int> insert(Medication m) => AppDatabase.insertMedication(m);

  Future<int> update(Medication m) => AppDatabase.updateMedication(m);

  Future<int> delete(int id) => AppDatabase.deleteMedication(id);

  /// Ajoute de la quantité au stock et enregistre le mouvement.
  Future<void> addStock(int medicationId, int quantite) async {
    final m = await AppDatabase.getMedicationById(medicationId);
    if (m == null) return;
    await AppDatabase.updateMedication(m.copyWith(quantite: m.quantite + quantite));
    await AppDatabase.insertStockMovement(StockMovement(
      medicationId: medicationId,
      type: StockMovementType.ajout,
      quantite: quantite,
      date: DateTime.now(),
    ));
  }

  /// Retire de la quantité (prise) et enregistre le mouvement.
  Future<void> takeStock(int medicationId, int quantite) async {
    final m = await AppDatabase.getMedicationById(medicationId);
    if (m == null) return;
    final newQty = (m.quantite - quantite).clamp(0, m.quantite);
    await AppDatabase.updateMedication(m.copyWith(quantite: newQty));
    await AppDatabase.insertStockMovement(StockMovement(
      medicationId: medicationId,
      type: StockMovementType.prise,
      quantite: quantite,
      date: DateTime.now(),
    ));
  }

  Future<List<StockMovement>> getMovements(int medicationId, {int limit = 50}) =>
      AppDatabase.getMovementsForMedication(medicationId, limit: limit);
}
