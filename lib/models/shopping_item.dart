class ShoppingItem {
  final int? id;
  final int? medicationId;
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'medication_id': medicationId,
        'label': label,
        'checked': checked ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
      };

  factory ShoppingItem.fromMap(Map<String, dynamic> m) => ShoppingItem(
        id: m['id'] as int?,
        medicationId: m['medication_id'] as int?,
        label: m['label'] as String,
        checked: (m['checked'] as int?) == 1,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  ShoppingItem copyWith({
    int? id,
    int? medicationId,
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
