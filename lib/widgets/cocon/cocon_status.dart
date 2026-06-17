import '../../models/medication.dart';
import '../../theme/cocon_theme.dart';

/// Détermine le statut sémantique Cocon d'un médicament.
/// Priorité : périmé > bientôt périmé > rupture > stock bas > ok.
MedStatus statusOf(Medication m) {
  if (m.estPerime) return MedStatus.perime;
  if (m.estBientotPerime) return MedStatus.bientot;
  if (m.stockFaible) return m.quantite <= 0 ? MedStatus.rupture : MedStatus.bas;
  return MedStatus.ok;
}
