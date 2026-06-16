import 'package:cloud_firestore/cloud_firestore.dart';

class ShoppingItem {
  final String? id;
  final String? medicationId;
  final String label;
  final bool checked;
  final DateTime createdAt;

  const ShoppingItem({
    this.id,
    this.medicationId,
    required this.label,
    this.checked = false,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'medicationId': medicationId,
        'label': label,
        'checked': checked,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ShoppingItem.fromFirestore(String id, Map<String, dynamic> data) => ShoppingItem(
        id: id,
        medicationId: data['medicationId'] as String?,
        label: data['label'] as String,
        checked: data['checked'] as bool? ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

  ShoppingItem copyWith({
    String? id,
    String? medicationId,
    String? label,
    bool? checked,
    DateTime? createdAt,
  }) =>
      ShoppingItem(
        id: id ?? this.id,
        medicationId: medicationId ?? this.medicationId,
        label: label ?? this.label,
        checked: checked ?? this.checked,
        createdAt: createdAt ?? this.createdAt,
      );
}
