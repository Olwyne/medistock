import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle représentant un médicament dans l'inventaire (doc Firestore).
class Medication {
  /// Id du document Firestore. Null avant la première sauvegarde.
  final String? id;
  final String codeScanned;
  final String nom;
  final int quantite;
  final String unite; // Comprimé, Plaquette, Boîte, Sachet, Flacon, ML, Tube
  final int? quantiteParUnite; // ex: 30 comprimés par plaquette
  final DateTime? datePeremption;
  final String? lieu;
  final List<String> memberIds;
  final int seuilAlerte;
  final String? noticeUrl;
  final String? photoPath;
  final String? dci; // substance(s) active(s) / ingrédient
  final String? indication; // à quoi ça sert (maux de tête, antibiotique...)
  final String? posologie;
  final String? precautions; // effets secondaires / précautions d'usage

  const Medication({
    this.id,
    required this.codeScanned,
    required this.nom,
    required this.quantite,
    this.unite = 'Plaquette',
    this.quantiteParUnite,
    this.datePeremption,
    this.lieu,
    this.memberIds = const [],
    this.seuilAlerte = 0,
    this.noticeUrl,
    this.photoPath,
    this.dci,
    this.indication,
    this.posologie,
    this.precautions,
  });

  Medication copyWith({
    String? id,
    String? codeScanned,
    String? nom,
    int? quantite,
    String? unite,
    int? quantiteParUnite,
    DateTime? datePeremption,
    String? lieu,
    List<String>? memberIds,
    int? seuilAlerte,
    String? noticeUrl,
    String? photoPath,
    String? dci,
    String? indication,
    String? posologie,
    String? precautions,
  }) {
    return Medication(
      id: id ?? this.id,
      codeScanned: codeScanned ?? this.codeScanned,
      nom: nom ?? this.nom,
      quantite: quantite ?? this.quantite,
      unite: unite ?? this.unite,
      quantiteParUnite: quantiteParUnite ?? this.quantiteParUnite,
      datePeremption: datePeremption ?? this.datePeremption,
      lieu: lieu ?? this.lieu,
      memberIds: memberIds ?? this.memberIds,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      noticeUrl: noticeUrl ?? this.noticeUrl,
      photoPath: photoPath ?? this.photoPath,
      dci: dci ?? this.dci,
      indication: indication ?? this.indication,
      posologie: posologie ?? this.posologie,
      precautions: precautions ?? this.precautions,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'codeScanned': codeScanned,
      'nom': nom,
      'quantite': quantite,
      'unite': unite,
      'quantiteParUnite': quantiteParUnite,
      'datePeremption': datePeremption != null ? Timestamp.fromDate(datePeremption!) : null,
      'lieu': lieu,
      'memberIds': memberIds,
      'seuilAlerte': seuilAlerte,
      'noticeUrl': noticeUrl,
      'photoPath': photoPath,
      'dci': dci,
      'indication': indication,
      'posologie': posologie,
      'precautions': precautions,
    };
  }

  factory Medication.fromFirestore(String id, Map<String, dynamic> data) {
    return Medication(
      id: id,
      codeScanned: data['codeScanned'] as String? ?? '',
      nom: data['nom'] as String,
      quantite: data['quantite'] as int,
      unite: data['unite'] as String? ?? 'Plaquette',
      quantiteParUnite: data['quantiteParUnite'] as int?,
      datePeremption: (data['datePeremption'] as Timestamp?)?.toDate(),
      lieu: data['lieu'] as String?,
      memberIds: (data['memberIds'] as List?)?.cast<String>() ??
          (data['memberId'] != null ? [data['memberId'] as String] : const []),
      seuilAlerte: data['seuilAlerte'] as int? ?? 0,
      noticeUrl: data['noticeUrl'] as String?,
      photoPath: data['photoPath'] as String?,
      dci: data['dci'] as String?,
      indication: data['indication'] as String?,
      posologie: data['posologie'] as String?,
      precautions: data['precautions'] as String?,
    );
  }

  /// Jours restants avant péremption (null si pas de date).
  int? get joursAvantPeremption {
    if (datePeremption == null) return null;
    final now = DateTime.now();
    final end = DateTime(datePeremption!.year, datePeremption!.month, datePeremption!.day);
    final start = DateTime(now.year, now.month, now.day);
    return end.difference(start).inDays;
  }

  bool get estBientotPerime {
    final j = joursAvantPeremption;
    return j != null && j >= 0 && j <= 30;
  }

  bool get estPerime {
    final j = joursAvantPeremption;
    return j != null && j < 0;
  }

  bool get stockFaible => seuilAlerte > 0 && quantite <= seuilAlerte;
}
