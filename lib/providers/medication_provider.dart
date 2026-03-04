import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../models/stock_movement.dart';
import '../repositories/medication_repository.dart';

class MedicationProvider with ChangeNotifier {
  final MedicationRepository _repo = MedicationRepository();

  List<Medication> _medications = [];
  bool _loading = false;
  String? _error;

  List<Medication> get medications => List.unmodifiable(_medications);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _medications = await _repo.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Medication?> getById(int id) => _repo.getById(id);

  Future<Medication?> getByCode(String code) => _repo.getByCode(code);

  Future<void> add(Medication m) async {
    await _repo.insert(m);
    await load();
  }

  Future<void> update(Medication m) async {
    await _repo.update(m);
    await load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await load();
  }

  Future<void> addStock(int medicationId, int quantite) async {
    await _repo.addStock(medicationId, quantite);
    await load();
  }

  Future<void> takeStock(int medicationId, int quantite) async {
    await _repo.takeStock(medicationId, quantite);
    await load();
  }

  Future<List<StockMovement>> getMovements(int medicationId, {int limit = 50}) =>
      _repo.getMovements(medicationId, limit: limit);

  List<Medication> get bientotPerimes =>
      _medications.where((m) => m.estBientotPerime && !m.estPerime).toList();

  List<Medication> get stockFaible => _medications.where((m) => m.stockFaible).toList();

  List<Medication> get perimes => _medications.where((m) => m.estPerime).toList();
}
