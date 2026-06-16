import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base de l'API BDPM (data.gouv.fr / medicaments-api.giygas.dev).
const _baseUrl = 'https://medicaments-api.giygas.dev';

/// Résultat de la recherche par CIP : nom, forme, unité et quantité suggérées.
class MedicationApiResult {
  final String nom;
  final String? formePharmaceutique;
  final String? suggestedUnite;
  final int? suggestedQuantiteParUnite;

  const MedicationApiResult({
    required this.nom,
    this.formePharmaceutique,
    this.suggestedUnite,
    this.suggestedQuantiteParUnite,
  });
}

/// Erreur API : type et message optionnel.
enum ApiErrorType { network, timeout, rateLimit, server, unknown }

class ApiError {
  final ApiErrorType type;
  final String? message;

  const ApiError(this.type, [this.message]);
}

/// Réponse du lookup : soit un résultat soit une erreur.
class MedicationApiLookupResult {
  final MedicationApiResult? data;
  final ApiError? error;

  const MedicationApiLookupResult({this.data, this.error});
  bool get isSuccess => data != null && error == null;
}

/// Service d'appel à l'API des médicaments français (recherche par CIP).
class MedicationApiService {
  static final MedicationApiService _instance = MedicationApiService._();
  factory MedicationApiService() => _instance;

  MedicationApiService._();

  /// Normalise le code scanné pour l'API : CIP7 (7 chiffres) ou CIP13 (13 chiffres).
  static String? _normalizeCip(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 7) return digits;
    if (digits.length == 13) return digits;
    if (digits.length == 8) return digits.length >= 7 ? digits.substring(0, 7) : null;
    return digits.isNotEmpty ? digits : null;
  }

  /// Recherche un médicament par code CIP (CIP7 ou CIP13).
  /// Retourne un MedicationApiLookupResult (data ou error).
  Future<MedicationApiLookupResult> lookupByCip(String codeScanned) async {
    final cip = _normalizeCip(codeScanned);
    if (cip == null || cip.isEmpty) {
      return const MedicationApiLookupResult(error: ApiError(ApiErrorType.unknown, 'Code invalide'));
    }

    try {
      final uri = Uri.parse('$_baseUrl/v1/medicaments').replace(queryParameters: {'cip': cip});
      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
        onTimeout: () => http.Response('', 408),
      );

      if (response.statusCode == 408) {
        return const MedicationApiLookupResult(error: ApiError(ApiErrorType.timeout));
      }
      if (response.statusCode == 429) {
        return const MedicationApiLookupResult(error: ApiError(ApiErrorType.rateLimit));
      }
      if (response.statusCode >= 500) {
        return MedicationApiLookupResult(error: ApiError(ApiErrorType.server, 'Erreur serveur ${response.statusCode}'));
      }
      if (response.statusCode != 200) {
        return MedicationApiLookupResult(error: ApiError(ApiErrorType.unknown, 'HTTP ${response.statusCode}'));
      }

      final decoded = json.decode(response.body);
      Map<String, dynamic>? obj;
      if (decoded is Map<String, dynamic>) {
        obj = decoded;
      } else if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
        obj = decoded.first as Map<String, dynamic>;
      }
      if (obj == null) {
        return const MedicationApiLookupResult(error: ApiError(ApiErrorType.unknown, 'Réponse invalide'));
      }

      final result = _fromObj(obj);
      if (result == null) {
        return const MedicationApiLookupResult(error: ApiError(ApiErrorType.unknown, 'Médicament non trouvé'));
      }
      return MedicationApiLookupResult(data: result);
    } on http.ClientException catch (e) {
      return MedicationApiLookupResult(error: ApiError(ApiErrorType.network, e.message));
    } on FormatException catch (e) {
      return MedicationApiLookupResult(error: ApiError(ApiErrorType.unknown, e.message));
    } catch (e) {
      return MedicationApiLookupResult(error: ApiError(ApiErrorType.unknown, e.toString()));
    }
  }

  /// Recherche par nom (1 à 6 mots, min 3 caractères). Pour l'autocomplétion à la saisie.
  Future<List<MedicationApiResult>> searchByName(String query) async {
    final term = query.trim();
    if (term.length < 3) return [];
    try {
      final uri = Uri.parse('$_baseUrl/v1/medicaments').replace(queryParameters: {'search': term});
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return [];
      final decoded = json.decode(response.body);
      final list = decoded is List
          ? decoded
          : decoded is Map<String, dynamic> && decoded['data'] is List
              ? decoded['data'] as List
              : const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(_fromObj)
          .whereType<MedicationApiResult>()
          .take(15)
          .toList();
    } catch (_) {
      return [];
    }
  }

  MedicationApiResult? _fromObj(Map<String, dynamic> obj) {
    final nom = obj['elementPharmaceutique'] as String?;
    if (nom == null || nom.isEmpty) return null;

    final forme = obj['formePharmaceutique'] as String?;
    final presentation = obj['presentation'] as List<dynamic>?;
    String? suggestedUnite;
    int? suggestedQuantiteParUnite;
    if (presentation != null && presentation.isNotEmpty) {
      final first = presentation.first;
      if (first is Map<String, dynamic>) {
        final libelle = first['libelle'] as String? ?? '';
        final parsed = parsePresentationLibelle(libelle, forme);
        suggestedUnite = parsed.$1;
        suggestedQuantiteParUnite = parsed.$2;
      }
    }
    if (suggestedUnite == null && forme != null) {
      suggestedUnite = _uniteFromForme(forme);
    }
    return MedicationApiResult(
      nom: nom.trim(),
      formePharmaceutique: forme?.trim(),
      suggestedUnite: suggestedUnite,
      suggestedQuantiteParUnite: suggestedQuantiteParUnite,
    );
  }

  /// Extrait unité et quantité depuis le libellé de présentation BDPM.
  /// Ex: "plaquette(s) ... de 16 comprimé(s)" → (Plaquette, 16). Public pour les tests.
  static (String?, int?) parsePresentationLibelle(String libelle, String? forme) {
    if (libelle.isEmpty) return (null, null);
    final l = libelle.toLowerCase();
    String? unit;
    int? qte;

    // "de 30 comprimé(s)" ou "30 comprimé(s)" ou "16 comprimé(s)"
    final comprMatch = RegExp(r'(?:de\s+)?(\d+)\s+comprim[eé](?:s)?').firstMatch(l);
    if (comprMatch != null) {
      qte = int.tryParse(comprMatch.group(1) ?? '');
      if (l.contains('plaquette')) {
        unit = 'Plaquette';
      } else if (l.contains('boîte') || l.contains('boite')) {
        unit = 'Boîte';
      } else {
        unit = 'Comprimé';
      }
    }

    // "de X ml" ou "X ml"
    final mlMatch = RegExp(r'(?:de\s+)?(\d+)\s*ml').firstMatch(l);
    if (mlMatch != null) {
      qte = int.tryParse(mlMatch.group(1) ?? '');
      if (l.contains('flacon') || l.contains('gouttes')) {
        unit = 'Flacon';
      } else {
        unit = 'ML';
      }
    }

    // "X sachet(s)" ou "de X sachet(s)"
    final sachetMatch = RegExp(r'(?:de\s+)?(\d+)\s+sachet(?:s)?').firstMatch(l);
    if (sachetMatch != null) {
      qte = int.tryParse(sachetMatch.group(1) ?? '');
      unit = 'Sachet';
    }

    // "X gélule(s)" ou "de X gélule(s)" → comme comprimé
    final gelMatch = RegExp(r'(?:de\s+)?(\d+)\s+g[eé]lule(?:s)?').firstMatch(l);
    if (gelMatch != null && unit == null) {
      qte = int.tryParse(gelMatch.group(1) ?? '');
      if (l.contains('plaquette')) {
        unit = 'Plaquette';
      } else if (l.contains('boîte') || l.contains('boite')) {
        unit = 'Boîte';
      } else {
        unit = 'Comprimé';
      }
    }

    // Unité sans nombre explicite : plaquette, boîte, flacon
    if (unit == null) {
      if (l.contains('plaquette')) {
        unit = 'Plaquette';
      } else if (l.contains('flacon')) {
        unit = 'Flacon';
      } else if (l.contains('boîte') || l.contains('boite')) {
        unit = 'Boîte';
      } else if (l.contains('sachet')) {
        unit = 'Sachet';
      } else if (l.contains('tube')) {
        unit = 'Tube';
      }
    }

    return (unit, qte);
  }

  static String? _uniteFromForme(String forme) {
    final f = forme.toLowerCase();
    if (f.contains('comprimé') || f.contains('gélule')) return 'Comprimé';
    if (f.contains('plaquette')) return 'Plaquette';
    if (f.contains('sachet')) return 'Sachet';
    if (f.contains('solution') || f.contains('sirop') || f.contains('gouttes')) return 'Flacon';
    if (f.contains('ml')) return 'ML';
    if (f.contains('gel') || f.contains('crème') || f.contains('pommade')) return 'Tube';
    return 'Boîte';
  }
}
