import 'package:flutter/foundation.dart';
import '../data/firestore_repository.dart';
import '../models/medication.dart';
import '../models/shopping_item.dart';
import 'auth_provider.dart';

class ShoppingProvider extends ChangeNotifier {
  ShoppingProvider({AuthProvider? auth}) : _auth = auth {
    _auth?.addListener(_onAuthChanged);
  }

  final AuthProvider? _auth;

  void _onAuthChanged() {
    final auth = _auth;
    if (auth != null && !auth.isSignedIn) clear();
  }

  List<ShoppingItem> _items = [];

  List<ShoppingItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) {
      _items = [];
      notifyListeners();
      return;
    }
    _items = await FirestoreRepository.getShoppingItems(familyId);
    notifyListeners();
  }

  Future<void> addItem({String? label, String? medicationId}) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    final l = label?.trim() ?? '';
    if (l.isEmpty) return;
    final item = ShoppingItem(
      medicationId: medicationId,
      label: l,
      checked: false,
      createdAt: DateTime.now(),
    );
    await FirestoreRepository.insertShoppingItem(familyId, item);
    await load();
  }

  Future<void> addFromMedications(List<Medication> medications) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    for (final m in medications) {
      final label = m.nom;
      final existing = _items.any((i) => i.medicationId == m.id || (i.label == label && !i.checked));
      if (existing) continue;
      await FirestoreRepository.insertShoppingItem(
        familyId,
        ShoppingItem(medicationId: m.id, label: label, checked: false, createdAt: DateTime.now()),
      );
    }
    await load();
  }

  Future<void> toggleChecked(ShoppingItem item) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null || item.id == null) return;
    final updated = item.copyWith(checked: !item.checked);
    await FirestoreRepository.updateShoppingItem(familyId, updated);
    await load();
  }

  Future<void> deleteItem(String id) async {
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    await FirestoreRepository.deleteShoppingItem(familyId, id);
    await load();
  }

  /// Vide les données en mémoire (après déconnexion).
  void clear() {
    _items = [];
    notifyListeners();
  }

  String shareableText() {
    if (_items.isEmpty) return '';
    final buffer = StringBuffer();
    for (final i in _items) {
      buffer.writeln('${i.checked ? '☑' : '☐'} ${i.label}');
    }
    return buffer.toString();
  }
}
