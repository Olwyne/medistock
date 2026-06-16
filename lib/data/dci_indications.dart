/// Suggestion d'indication générale à partir de la substance (DCI).
/// Couvre les substances OTC françaises les plus courantes. Volontairement limité
/// à une catégorie générale (pas de posologie/effets secondaires) : une suggestion
/// de dosage ou d'effets indésirables erronée serait dangereuse sans source médicale
/// vérifiée — seule l'indication, éditable par l'utilisateur, est auto-remplie.
const Map<String, String> dciIndications = {
  'paracétamol': 'Douleur, fièvre',
  'ibuprofène': 'Douleur, inflammation, fièvre',
  'acide acétylsalicylique': 'Douleur, fièvre (anti-inflammatoire)',
  'aspirine': 'Douleur, fièvre (anti-inflammatoire)',
  'amoxicilline': 'Infection bactérienne (antibiotique)',
  'azithromycine': 'Infection bactérienne (antibiotique)',
  'phloroglucinol': 'Douleurs digestives, spasmes',
  'diosmectite': 'Diarrhée',
  'lopéramide': 'Diarrhée',
  'alginate': 'Brûlures d\'estomac, reflux',
  'oméprazole': 'Brûlures d\'estomac, reflux, ulcère',
  'salbutamol': 'Asthme, gêne respiratoire',
  'amylmétacrésol': 'Maux de gorge',
  'nacl 0,9 %': 'Hygiène nasale',
  'trolamine': 'Brûlures légères, irritations cutanées',
  'povidone iodée': 'Désinfection des plaies',
  'magnésium b6': 'Fatigue, carence en magnésium',
  'acide ascorbique': 'Carence en vitamine C, fatigue',
  'vitamine d': 'Carence en vitamine D',
  'cétirizine': 'Allergies (antihistaminique)',
  'loratadine': 'Allergies (antihistaminique)',
  'dompéridone': 'Nausées, vomissements',
};

/// Recherche insensible à la casse/accents approximative (clé en minuscules).
String? suggestIndicationFromDci(String? dci) {
  if (dci == null || dci.trim().isEmpty) return null;
  final parts = dci.toLowerCase().split('+').map((s) => s.trim());
  for (final part in parts) {
    final hit = dciIndications[part];
    if (hit != null) return hit;
  }
  return null;
}
