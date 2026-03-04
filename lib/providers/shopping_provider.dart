import 'package:flutter/foundation.dart';
import '../data/database.dart';
import '../models/medication.dart';
import '../models/shopping_item.dart';

class ShoppingProvider extends ChangeNotifier {
  List<ShoppingItem> _items = [];

  List<ShoppingItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    _items = await AppDatabase.getShoppingItems();
    notifyListeners();
  }

  Future<void> addItem({String? label, int? medicationId}) async {
    final l = label?.trim() ?? '';
    if (l.isEmpty) return;
    final item = ShoppingItem(
      medicationId: medicationId,
      label: l,
      checked: false,
      createdAt: DateTime.now(),
    );
    await AppDatabase.insertShoppingItem(item);
    await load();
  }

  Future<void> addFromMedications(List<Medication> medications) async {
    for (final m in medications) {
      final label = m.nom;
      final existing = _items.any((i) => i.medicationId == m.id || (i.label == label && !i.checked));
      if (existing) continue;
      await AppDatabase.insertShoppingItem(ShoppingItem(
        medicationId: m.id,
        label: label,
        checked: false,
        createdAt: DateTime.now(),
      ));
    }
    await load();
  }

  Future<void> toggleChecked(ShoppingItem item) async {
    if (item.id == null) return;
    final updated = item.copyWith(checked: !item.checked);
    await AppDatabase.updateShoppingItem(updated);
    await load();
  }

  Future<void> deleteItem(int id) async {
    await AppDatabase.deleteShoppingItem(id);
    await load();
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
