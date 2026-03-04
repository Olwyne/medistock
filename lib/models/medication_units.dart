/// Unités de stock prédéfinies pour les médicaments.
class MedicationUnits {
  static const String comprime = 'Comprimé';
  static const String plaquette = 'Plaquette';
  static const String boite = 'Boîte';
  static const String sachet = 'Sachet';
  static const String flacon = 'Flacon';
  static const String ml = 'ML';
  static const String tube = 'Tube';

  static const List<String> all = [
    comprime,
    plaquette,
    boite,
    sachet,
    flacon,
    ml,
    tube,
  ];

  /// Suggère une unité à partir de la forme pharmaceutique (API BDPM).
  static String suggestFromForme(String? forme) {
    if (forme == null || forme.isEmpty) return plaquette;
    final f = forme.toLowerCase();
    if (f.contains('comprimé')) return comprime;
    if (f.contains('plaquette')) return plaquette;
    if (f.contains('sachet')) return sachet;
    if (f.contains('solution') || f.contains('sirop') || f.contains('suspension') ||
        f.contains('gouttes') || f.contains('liquide')) {
      return flacon;
    }
    if (f.contains('ml') || f.contains(' g ')) {
      return ml;
    }
    if (f.contains('gel') || f.contains('crème') || f.contains('pommade')) return tube;
    return boite;
  }
}
