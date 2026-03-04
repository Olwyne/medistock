/// Type de mouvement de stock.
enum StockMovementType {
  ajout,
  prise,
}

/// Un mouvement de stock (ajout ou prise).
class StockMovement {
  final int? id;
  final int medicationId;
  final StockMovementType type;
  final int quantite;
  final DateTime date;

  const StockMovement({
    this.id,
    required this.medicationId,
    required this.type,
    required this.quantite,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'type': type == StockMovementType.ajout ? 'ajout' : 'prise',
      'quantite': quantite,
      'date': date.toIso8601String(),
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] as int?,
      medicationId: map['medication_id'] as int,
      type: map['type'] == 'ajout' ? StockMovementType.ajout : StockMovementType.prise,
      quantite: map['quantite'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }
}
