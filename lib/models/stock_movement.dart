import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de mouvement de stock.
enum StockMovementType {
  ajout,
  prise,
}

/// Un mouvement de stock (ajout ou prise), sous-collection d'un médicament.
class StockMovement {
  final String? id;
  final String medicationId;
  final StockMovementType type;
  final double quantite;
  final DateTime date;

  const StockMovement({
    this.id,
    required this.medicationId,
    required this.type,
    required this.quantite,
    required this.date,
  });

  /// `familyId` est dénormalisé dans le doc pour permettre la collectionGroup query des stats.
  Map<String, dynamic> toFirestore({required String familyId}) {
    return {
      'familyId': familyId,
      'type': type == StockMovementType.ajout ? 'ajout' : 'prise',
      'quantite': quantite,
      'date': Timestamp.fromDate(date),
    };
  }

  factory StockMovement.fromFirestore(String id, String medicationId, Map<String, dynamic> data) {
    return StockMovement(
      id: id,
      medicationId: medicationId,
      type: data['type'] == 'ajout' ? StockMovementType.ajout : StockMovementType.prise,
      quantite: (data['quantite'] as num? ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
    );
  }
}
