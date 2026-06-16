/// Décodage du contenu scanné (QR / Data Matrix).
/// En France: CIP, GS1, ou URL vers notice.
class ScanResult {
  final String raw;
  final String? cip;
  final String? gtin;
  final String? noticeUrl;
  final String? suggestedName;

  const ScanResult({
    required this.raw,
    this.cip,
    this.gtin,
    this.noticeUrl,
    this.suggestedName,
  });
}

class ScanService {
  /// Parse le contenu brut du code et extrait ce qui est reconnu.
  static ScanResult parse(String raw) {
    final trimmed = raw.trim();
    String? cip;
    String? gtin;
    String? noticeUrl;
    String? suggestedName;

    // URL (notice électronique)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      noticeUrl = trimmed;
      suggestedName = null;
    }
    // CIP français (7 ou 8 chiffres)
    else if (RegExp(r'^\d{7,8}$').hasMatch(trimmed)) {
      cip = trimmed;
      suggestedName = 'Médicament CIP $trimmed';
    }
    // CIP13 brut (code-barres simple, sans encodage GS1)
    else if (RegExp(r'^\d{13}$').hasMatch(trimmed)) {
      cip = trimmed;
      suggestedName = 'Médicament CIP $trimmed';
    }
    // GS1 Data Matrix : AI(01) = GTIN-14, avec ou sans parenthèses autour de l'AI.
    // Le GTIN-14 français = "0" + CIP13 -> on retire le zéro de tête.
    else if (RegExp(r'01(\d{14})').firstMatch(trimmed.replaceAll(RegExp(r'[()]'), '')) != null) {
      final gtinVal = RegExp(r'01(\d{14})').firstMatch(trimmed.replaceAll(RegExp(r'[()]'), ''))!.group(1)!;
      gtin = gtinVal;
      cip = gtinVal.startsWith('0') ? gtinVal.substring(1) : gtinVal;
      suggestedName = 'Médicament CIP $cip';
    }
    // Autre: on garde le brut comme identifiant
    else {
      suggestedName = trimmed.length > 20 ? '${trimmed.substring(0, 20)}...' : trimmed;
    }

    return ScanResult(
      raw: raw,
      cip: cip,
      gtin: gtin,
      noticeUrl: noticeUrl,
      suggestedName: suggestedName,
    );
  }
}
