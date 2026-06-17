import 'package:flutter/foundation.dart';
import '../data/firestore_repository.dart';
import '../models/medication.dart';
import '../models/stock_movement.dart';
import 'auth_provider.dart';

class MedicationProvider with ChangeNotifier {
  MedicationProvider({AuthProvider? auth}) : _auth = auth {
    _auth?.addListener(_onAuthChanged);
  }

  final AuthProvider? _auth;

  void _onAuthChanged() {
    final auth = _auth;
    if (auth != null && !auth.isSignedIn) clear();
  }

  List<Medication> _medications = [];
  bool _loading = false;
  String? _error;

  List<Medication> get medications => List.unmodifiable(_medications);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) {
      _medications = [];
      notifyListeners();
      return;
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _medications = await FirestoreRepository.getAllMedications(familyId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Conservé pour compat avec les écrans existants ; recharge simplement la liste.
  Future<void> loadWithSync(String? familyId) async => load();

  Future<Medication?> getById(String? id) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null || id == null) return null;
    return FirestoreRepository.getMedicationById(familyId, id);
  }

  Future<Medication?> getByCode(String code) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return null;
    return FirestoreRepository.getMedicationByCode(familyId, code);
  }

  Future<void> add(Medication m, {String? familyId}) async {
    final fid = familyId ?? _auth?.currentFamilyId;
    if (fid == null) return;
    await FirestoreRepository.insertMedication(fid, m);
    await load();
  }

  Future<void> update(Medication m) async {
    final fid = _auth?.currentFamilyId;
    if (fid == null) return;
    await FirestoreRepository.updateMedication(fid, m);
    await load();
  }

  Future<void> delete(String id) async {
    final fid = _auth?.currentFamilyId;
    if (fid == null) return;
    await FirestoreRepository.deleteMedication(fid, id);
    await load();
  }

  Future<void> addStock(String? medicationId, double quantite) async {
    final fid = _auth?.currentFamilyId;
    if (fid == null || medicationId == null) return;
    await FirestoreRepository.addStock(fid, medicationId, quantite);
    await load();
  }

  Future<void> takeStock(String? medicationId, double quantite) async {
    final fid = _auth?.currentFamilyId;
    if (fid == null || medicationId == null) return;
    await FirestoreRepository.takeStock(fid, medicationId, quantite);
    await load();
  }

  Future<List<StockMovement>> getMovements(String? medicationId, {int limit = 50}) async {
    final fid = _auth?.currentFamilyId;
    if (fid == null || medicationId == null) return [];
    return FirestoreRepository.getMovementsForMedication(fid, medicationId, limit: limit);
  }

  /// Vide les données en mémoire (après déconnexion).
  void clear() {
    _medications = [];
    _error = null;
    notifyListeners();
  }

  List<Medication> get bientotPerimes =>
      _medications.where((m) => m.estBientotPerime && !m.estPerime).toList();

  List<Medication> get stockFaible => _medications.where((m) => m.stockFaible).toList();

  List<Medication> get perimes => _medications.where((m) => m.estPerime).toList();
}
