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
    // GS1 peut commencer par (01) pour GTIN, etc.
    else if (trimmed.contains('(01)')) {
      final match = RegExp(r'\(01\)(\d{14})').firstMatch(trimmed);
      if (match != null) gtin = match.group(1);
      suggestedName = gtin != null ? 'Médicament $gtin' : null;
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
