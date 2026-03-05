import 'package:flutter/foundation.dart';
import '../data/database.dart';
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
    if (kIsWeb) {
      _items = [];
      notifyListeners();
      return;
    }
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) {
      _items = [];
      notifyListeners();
      return;
    }
    _items = await AppDatabase.getShoppingItems(familyId: familyId);
    notifyListeners();
  }

  Future<void> addItem({String? label, int? medicationId}) async {
    if (kIsWeb) return;
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
    await AppDatabase.insertShoppingItem(item, familyId: familyId);
    await load();
  }

  Future<void> addFromMedications(List<Medication> medications) async {
    if (kIsWeb) return;
    final familyId = _auth?.currentFamilyId;
    if (familyId == null) return;
    for (final m in medications) {
      final label = m.nom;
      final existing = _items.any((i) => i.medicationId == m.id || (i.label == label && !i.checked));
      if (existing) continue;
      await AppDatabase.insertShoppingItem(ShoppingItem(
        medicationId: m.id,
        label: label,
        checked: false,
        createdAt: DateTime.now(),
      ), familyId: familyId);
    }
    await load();
  }

  Future<void> toggleChecked(ShoppingItem item) async {
    if (kIsWeb || item.id == null) return;
    final updated = item.copyWith(checked: !item.checked);
    await AppDatabase.updateShoppingItem(updated);
    await load();
  }

  Future<void> deleteItem(int id) async {
    if (kIsWeb) return;
    await AppDatabase.deleteShoppingItem(id);
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
