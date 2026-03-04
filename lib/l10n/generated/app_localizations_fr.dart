// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get inventaire_title => 'Inventaire';

  @override
  String get scanner_title => 'Scanner';

  @override
  String get alertes_title => 'Alertes';

  @override
  String get settings_title => 'Réglages';

  @override
  String get shopping_title => 'Liste de courses';

  @override
  String get stats_title => 'Statistiques';

  @override
  String get add => 'Ajouter';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get retry => 'Réessayer';

  @override
  String get theme => 'Thème';

  @override
  String get theme_system => 'Système';

  @override
  String get theme_light => 'Clair';

  @override
  String get theme_dark => 'Sombre';

  @override
  String get sort => 'Trier';

  @override
  String get sort_by_name => 'Par nom';

  @override
  String get sort_by_quantity => 'Par quantité';

  @override
  String get sort_by_expiry => 'Par péremption';

  @override
  String get filter => 'Filtrer';

  @override
  String get filter_all => 'Tous';

  @override
  String get filter_soon_expiry => 'Bientôt périmés';

  @override
  String get filter_low_stock => 'Stock faible';

  @override
  String get place => 'Lieu';

  @override
  String get export_csv => 'Exporter en CSV';

  @override
  String get export_csv_copied =>
      'Inventaire copié dans le presse-papier (CSV)';

  @override
  String get search_hint => 'Rechercher (nom, lieu)...';

  @override
  String get no_medication => 'Aucun médicament';

  @override
  String get no_medication_hint => 'Scannez un code ou ajoutez manuellement';

  @override
  String get add_medication => 'Ajouter un médicament';

  @override
  String get medications => 'Médicaments';

  @override
  String get soon_expiry => 'Bientôt périmés';

  @override
  String get low_stock => 'Stock faible';

  @override
  String get scan_add_to_stock => 'Ajouter au stock';

  @override
  String get scan_remove_from_stock => 'Retirer du stock';

  @override
  String get scan_hint_add => 'Scannez le code sur la boîte ou la plaquette';

  @override
  String get scan_hint_remove => 'Scannez le code du médicament à retirer';

  @override
  String get medication_added => 'Médicament ajouté à l\'inventaire';

  @override
  String get medication_removed => '1 unité retirée';

  @override
  String get add_to_inventory => 'Ajouter à l\'inventaire';

  @override
  String get already_in_inventory =>
      'Ce médicament est déjà dans l\'inventaire. Voulez-vous ajouter une quantité au stock ?';

  @override
  String get add_to_stock_confirm => 'Oui, ajouter au stock';

  @override
  String get yes_add_stock => 'Oui, ajouter au stock';

  @override
  String get no => 'Non';

  @override
  String get not_in_inventory => 'Médicament non trouvé dans l\'inventaire.';

  @override
  String get add_first => 'Ajoutez-le d\'abord.';

  @override
  String get medication_recognized => 'Médicament reconnu';

  @override
  String get api_error_hint =>
      'Impossible de récupérer le nom. Vous pouvez le saisir manuellement.';

  @override
  String get expired => 'Périmé';

  @override
  String get expires_in => 'Expire dans';

  @override
  String get days => 'j';

  @override
  String get no_alerts => 'Aucune alerte';

  @override
  String get no_alerts_hint => 'Vos stocks et dates sont OK';

  @override
  String get add_to_shopping_list => 'Ajouter à la liste de courses';

  @override
  String get detail => 'Détail';

  @override
  String get take_one => 'J\'en prends un';

  @override
  String get take_quantity => 'Prendre';

  @override
  String get remove_quantity => 'Retirer';

  @override
  String get add_stock => 'Ajouter au stock';

  @override
  String get view_notice => 'Voir la notice';

  @override
  String get expiry => 'Péremption';

  @override
  String get reminder => 'Rappel quotidien';

  @override
  String get daily_reminder => 'Rappel quotidien';

  @override
  String get not_set => 'Non défini';

  @override
  String get at => 'À';

  @override
  String get movement_history => 'Historique des mouvements';

  @override
  String get taken => 'Pris';

  @override
  String get added => 'Ajout';

  @override
  String get add_medication_title => 'Ajouter un médicament';

  @override
  String get edit_medication_title => 'Modifier le médicament';

  @override
  String get medication_name => 'Nom du médicament';

  @override
  String get medication_name_hint => 'Ex: Doliprane 1000mg';

  @override
  String get add_photo => 'Ajouter une photo';

  @override
  String get quantity => 'Quantité';

  @override
  String get unit => 'Unité';

  @override
  String get quantity_per_unit => 'Quantité par unité (optionnel)';

  @override
  String get quantity_per_unit_hint => 'Ex: 30 comprimés par plaquette';

  @override
  String get place_storage => 'Lieu de rangement (optionnel)';

  @override
  String get place_storage_hint => 'Ex: Armoire salle de bain';

  @override
  String get alert_stock_min => 'Alerte stock (quantité min)';

  @override
  String get alert_stock_hint => '0 = désactivé';

  @override
  String get expiry_date => 'Date de péremption (optionnel)';

  @override
  String get expiry_optional => 'Péremption';

  @override
  String get remove_date => 'Supprimer la date';

  @override
  String get required => 'Obligatoire';

  @override
  String get number_min => 'Nombre ≥ 0';

  @override
  String get delete_confirm => 'Supprimer';

  @override
  String get delete_medication_confirm =>
      'Supprimer ce médicament de l\'inventaire ?';

  @override
  String get first_day_of_week => 'Premier jour de la semaine';

  @override
  String get sunday => 'Dimanche';

  @override
  String get monday => 'Lundi';

  @override
  String get scan_sound => 'Son au scan';

  @override
  String get family => 'Famille';

  @override
  String get places => 'Lieux';

  @override
  String get health => 'Santé';

  @override
  String get allergies => 'Allergies';

  @override
  String get backup_restore => 'Sauvegarde / Restauration';

  @override
  String get backup => 'Sauvegarder mes données';

  @override
  String get restore => 'Restaurer';

  @override
  String get restore_warning => 'Écrasera les données actuelles.';

  @override
  String get backup_success => 'Sauvegarde créée';

  @override
  String get restore_success => 'Données restaurées';

  @override
  String get export_pdf_doctor => 'Exporter en PDF pour le médecin';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get english => 'English';

  @override
  String get onboarding_title1 => 'Scannez vos médicaments';

  @override
  String get onboarding_body1 =>
      'Scannez le code-barres ou Data Matrix sur la boîte pour ajouter un médicament à l\'inventaire.';

  @override
  String get onboarding_title2 => 'Retirez du stock';

  @override
  String get onboarding_body2 =>
      'Quand vous prenez un médicament, enregistrez la prise en un tap ou en scannant à nouveau.';

  @override
  String get onboarding_title3 => 'Consultez les alertes';

  @override
  String get onboarding_body3 =>
      'Restez informé des stocks faibles et des dates de péremption.';

  @override
  String get onboarding_title4 => 'Famille et lieux';

  @override
  String get onboarding_body4 =>
      'Organisez vos médicaments par personne et par lieu de rangement dans les réglages.';

  @override
  String get get_started => 'Commencer';

  @override
  String get next => 'Suivant';

  @override
  String get shopping_add_from_alerts => 'Ajouter depuis les alertes';

  @override
  String get shopping_add_item => 'Ajouter un article';

  @override
  String get shopping_share_list => 'Partager la liste';

  @override
  String get shopping_empty => 'Liste vide';

  @override
  String get shopping_list_updated => 'Liste mise à jour';

  @override
  String get stats_pastes_7 => 'Prises (7 jours)';

  @override
  String get stats_pastes_30 => 'Prises (30 jours)';

  @override
  String get stats_most_used => 'Plus consommés';

  @override
  String get check_with_doctor => 'Vérifier avec votre médecin ou pharmacien.';
}
