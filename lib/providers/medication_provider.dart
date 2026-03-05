import 'package:flutter/foundation.dart';
import '../core/env_config.dart';
import '../models/medication.dart';
import '../models/stock_movement.dart';
import '../repositories/medication_repository.dart';
import '../services/sync_service.dart';
import 'auth_provider.dart';

class MedicationProvider with ChangeNotifier {
  MedicationProvider({AuthProvider? auth}) : _auth = auth {
    _auth?.addListener(_onAuthChanged);
  }

  final AuthProvider? _auth;
  final MedicationRepository _repo = MedicationRepository();

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
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (kIsWeb) {
        if (EnvConfig.isConfigured && _auth?.currentFamilyId != null) {
          _medications = await SyncService.getMedicationsFromSupabase(_auth!.currentFamilyId!);
        } else {
          _medications = [];
        }
      } else {
        _medications = await _repo.getAll(familyId: _auth?.currentFamilyId);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Charge les données après sync depuis Supabase (mobile, quand une famille est sélectionnée).
  Future<void> loadWithSync(String? familyId) async {
    if (familyId != null && EnvConfig.isConfigured && !kIsWeb) {
      try {
        await SyncService.pull(familyId);
      } catch (_) {}
    }
    await load();
  }

  Future<Medication?> getById(dynamic id) async {
    if (kIsWeb) {
      final list = _medications.where((m) => m.serverId == id || m.id == id);
      return list.isEmpty ? null : list.first;
    }
    return _repo.getById(id is int ? id : int.tryParse(id.toString()) ?? 0, familyId: _auth?.currentFamilyId);
  }

  Future<Medication?> getByCode(String code) async {
    if (kIsWeb) {
      try {
        return _medications.firstWhere((m) => m.codeScanned == code);
      } catch (_) {
        return null;
      }
    }
    return _repo.getByCode(code, familyId: _auth?.currentFamilyId);
  }

  Future<void> add(Medication m, {String? familyId}) async {
    final fid = familyId ?? _auth?.currentFamilyId;
    if (kIsWeb && fid != null && EnvConfig.isConfigured) {
      try {
        await SyncService.pushMedication(m, fid);
        await load();
        return;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return;
      }
    }
    if (fid != null && EnvConfig.isConfigured && !kIsWeb) {
      try {
        final uuid = await SyncService.pushMedication(m, fid);
        m = m.copyWith(serverId: uuid);
      } catch (_) {}
    }
    await _repo.insert(m, familyId: fid);
    await load();
  }

  Future<void> update(Medication m) async {
    final fid = _auth?.currentFamilyId;
    if (kIsWeb && fid != null && m.serverId != null && EnvConfig.isConfigured) {
      try {
        await SyncService.updateMedicationInSupabase(m, fid);
        await load();
        return;
      } catch (e) {
        _error = e.toString();
        notifyListeners();
        return;
      }
    }
    await _repo.update(m);
    await load();
  }

  Future<void> delete(dynamic id) async {
    final fid = _auth?.currentFamilyId;
    if (kIsWeb && fid != null && EnvConfig.isConfigured) {
      final list = _medications.where((m) => m.serverId == id || m.id == id);
      final med = list.isEmpty ? null : list.first;
      if (med != null && med.serverId != null) {
        try {
          await SyncService.deleteMedicationFromSupabase(med.serverId);
          await load();
          return;
        } catch (e) {
          _error = e.toString();
          notifyListeners();
          return;
        }
      }
    }
    await _repo.delete(id is int ? id : int.parse(id.toString()));
    await load();
  }

  Future<void> addStock(dynamic medicationId, int quantite) async {
    if (medicationId == null) return;
    if (kIsWeb && _auth?.currentFamilyId != null && EnvConfig.isConfigured && medicationId is String) {
      final med = _medications.where((m) => m.serverId == medicationId).firstOrNull;
      if (med == null) return;
      final updated = med.copyWith(quantite: med.quantite + quantite);
      final fid = _auth!.currentFamilyId!;
      await SyncService.updateMedicationInSupabase(updated, fid);
      await SyncService.pushStockMovement(
        StockMovement(medicationId: 0, type: StockMovementType.ajout, quantite: quantite, date: DateTime.now()),
        medicationId,
        fid,
      );
      await load();
      return;
    }
    if (!kIsWeb) {
      await _repo.addStock(medicationId as int, quantite, familyId: _auth?.currentFamilyId);
      await load();
    }
  }

  Future<void> takeStock(dynamic medicationId, int quantite) async {
    if (medicationId == null) return;
    if (kIsWeb && _auth?.currentFamilyId != null && EnvConfig.isConfigured && medicationId is String) {
      final med = _medications.where((m) => m.serverId == medicationId).firstOrNull;
      if (med == null) return;
      final newQty = (med.quantite - quantite).clamp(0, med.quantite);
      final updated = med.copyWith(quantite: newQty);
      final fid = _auth!.currentFamilyId!;
      await SyncService.updateMedicationInSupabase(updated, fid);
      await SyncService.pushStockMovement(
        StockMovement(medicationId: 0, type: StockMovementType.prise, quantite: quantite, date: DateTime.now()),
        medicationId,
        fid,
      );
      await load();
      return;
    }
    if (!kIsWeb) {
      await _repo.takeStock(medicationId as int, quantite, familyId: _auth?.currentFamilyId);
      await load();
    }
  }

  Future<List<StockMovement>> getMovements(dynamic medicationId, {int limit = 50}) async {
    if (kIsWeb) return [];
    return _repo.getMovements(medicationId as int, limit: limit);
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
