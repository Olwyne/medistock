/// Modèle représentant un médicament dans l'inventaire.
class Medication {
  final int? id;
  /// UUID Supabase (sync), null en local seul.
  final String? serverId;
  final String codeScanned;
  final String nom;
  final int quantite;
  final String unite; // Comprimé, Plaquette, Boîte, Sachet, Flacon, ML, Tube
  final int? quantiteParUnite; // ex: 30 comprimés par plaquette
  final DateTime? datePeremption;
  final String? lieu;
  final int? memberId;
  final int seuilAlerte;
  final String? noticeUrl;
  final String? photoPath;

  const Medication({
    this.id,
    this.serverId,
    required this.codeScanned,
    required this.nom,
    required this.quantite,
    this.unite = 'Plaquette',
    this.quantiteParUnite,
    this.datePeremption,
    this.lieu,
    this.memberId,
    this.seuilAlerte = 0,
    this.noticeUrl,
    this.photoPath,
  });

  Medication copyWith({
    int? id,
    String? serverId,
    String? codeScanned,
    String? nom,
    int? quantite,
    String? unite,
    int? quantiteParUnite,
    DateTime? datePeremption,
    String? lieu,
    int? memberId,
    int? seuilAlerte,
    String? noticeUrl,
    String? photoPath,
  }) {
    return Medication(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      codeScanned: codeScanned ?? this.codeScanned,
      nom: nom ?? this.nom,
      quantite: quantite ?? this.quantite,
      unite: unite ?? this.unite,
      quantiteParUnite: quantiteParUnite ?? this.quantiteParUnite,
      datePeremption: datePeremption ?? this.datePeremption,
      lieu: lieu ?? this.lieu,
      memberId: memberId ?? this.memberId,
      seuilAlerte: seuilAlerte ?? this.seuilAlerte,
      noticeUrl: noticeUrl ?? this.noticeUrl,
      photoPath: photoPath ?? this.photoPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'remote_id': serverId,
      'code_scanned': codeScanned,
      'nom': nom,
      'quantite': quantite,
      'unite': unite,
      'quantite_par_unite': quantiteParUnite,
      'date_peremption': datePeremption?.toIso8601String(),
      'lieu': lieu,
      'member_id': memberId,
      'seuil_alerte': seuilAlerte,
      'notice_url': noticeUrl,
      'photo_path': photoPath,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      serverId: map['remote_id'] as String?,
      codeScanned: map['code_scanned'] as String,
      nom: map['nom'] as String,
      quantite: map['quantite'] as int,
      unite: map['unite'] as String? ?? 'Plaquette',
      quantiteParUnite: map['quantite_par_unite'] as int?,
      datePeremption: map['date_peremption'] != null
          ? DateTime.parse(map['date_peremption'] as String)
          : null,
      lieu: map['lieu'] as String?,
      memberId: map['member_id'] as int?,
      seuilAlerte: map['seuil_alerte'] as int? ?? 0,
      noticeUrl: map['notice_url'] as String?,
      photoPath: map['photo_path'] as String?,
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
