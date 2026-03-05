import '../data/database.dart';

class InteractionsService {
  /// Returns true if the medication name might match any registered allergy (simple keyword check).
  /// Does not block adding; caller should show a warning dialog.
  static Future<bool> hasPossibleInteraction(String medicationName, {String? familyId}) async {
    final allergies = await AppDatabase.getAllergies(familyId: familyId);
    if (allergies.isEmpty) return false;
    final nameLower = medicationName.trim().toLowerCase();
    if (nameLower.isEmpty) return false;
    for (final row in allergies) {
      final text = (row['allergy_text'] as String?)?.trim().toLowerCase() ?? '';
      if (text.isEmpty) continue;
      if (nameLower.contains(text) || text.contains(nameLower)) return true;
    }
    return false;
  }
}
