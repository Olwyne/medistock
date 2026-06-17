import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('fr')];

  /// No description provided for @inventaire_title.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire'**
  String get inventaire_title;

  /// No description provided for @scanner_title.
  ///
  /// In fr, this message translates to:
  /// **'Scanner'**
  String get scanner_title;

  /// No description provided for @alertes_title.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alertes_title;

  /// No description provided for @settings_title.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get settings_title;

  /// No description provided for @shopping_title.
  ///
  /// In fr, this message translates to:
  /// **'Liste de courses'**
  String get shopping_title;

  /// No description provided for @stats_title.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get stats_title;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @theme.
  ///
  /// In fr, this message translates to:
  /// **'Thème'**
  String get theme;

  /// No description provided for @theme_system.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get theme_system;

  /// No description provided for @theme_light.
  ///
  /// In fr, this message translates to:
  /// **'Clair'**
  String get theme_light;

  /// No description provided for @theme_dark.
  ///
  /// In fr, this message translates to:
  /// **'Sombre'**
  String get theme_dark;

  /// No description provided for @sort.
  ///
  /// In fr, this message translates to:
  /// **'Trier'**
  String get sort;

  /// No description provided for @sort_by_name.
  ///
  /// In fr, this message translates to:
  /// **'Par nom'**
  String get sort_by_name;

  /// No description provided for @sort_by_quantity.
  ///
  /// In fr, this message translates to:
  /// **'Par quantité'**
  String get sort_by_quantity;

  /// No description provided for @sort_by_expiry.
  ///
  /// In fr, this message translates to:
  /// **'Par péremption'**
  String get sort_by_expiry;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer'**
  String get filter;

  /// No description provided for @filter_all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filter_all;

  /// No description provided for @filter_soon_expiry.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt périmés'**
  String get filter_soon_expiry;

  /// No description provided for @filter_low_stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock faible'**
  String get filter_low_stock;

  /// No description provided for @place.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get place;

  /// No description provided for @export_csv.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en CSV'**
  String get export_csv;

  /// No description provided for @export_csv_copied.
  ///
  /// In fr, this message translates to:
  /// **'Inventaire copié dans le presse-papier (CSV)'**
  String get export_csv_copied;

  /// No description provided for @search_hint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher (nom, lieu)...'**
  String get search_hint;

  /// No description provided for @no_medication.
  ///
  /// In fr, this message translates to:
  /// **'Aucun médicament'**
  String get no_medication;

  /// No description provided for @no_medication_hint.
  ///
  /// In fr, this message translates to:
  /// **'Scannez un code ou ajoutez manuellement'**
  String get no_medication_hint;

  /// No description provided for @add_medication.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un médicament'**
  String get add_medication;

  /// No description provided for @medications.
  ///
  /// In fr, this message translates to:
  /// **'Médicaments'**
  String get medications;

  /// No description provided for @soon_expiry.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt périmés'**
  String get soon_expiry;

  /// No description provided for @low_stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock faible'**
  String get low_stock;

  /// No description provided for @scan_add_to_stock.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au stock'**
  String get scan_add_to_stock;

  /// No description provided for @scan_remove_from_stock.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du stock'**
  String get scan_remove_from_stock;

  /// No description provided for @scan_hint_add.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le code sur la boîte ou la plaquette'**
  String get scan_hint_add;

  /// No description provided for @scan_hint_remove.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le code du médicament à retirer'**
  String get scan_hint_remove;

  /// No description provided for @medication_added.
  ///
  /// In fr, this message translates to:
  /// **'Médicament ajouté à l\'inventaire'**
  String get medication_added;

  /// No description provided for @medication_removed.
  ///
  /// In fr, this message translates to:
  /// **'1 unité retirée'**
  String get medication_removed;

  /// No description provided for @add_to_inventory.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à l\'inventaire'**
  String get add_to_inventory;

  /// No description provided for @already_in_inventory.
  ///
  /// In fr, this message translates to:
  /// **'Ce médicament est déjà dans l\'inventaire. Voulez-vous ajouter une quantité au stock ?'**
  String get already_in_inventory;

  /// No description provided for @add_to_stock_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Oui, ajouter au stock'**
  String get add_to_stock_confirm;

  /// No description provided for @yes_add_stock.
  ///
  /// In fr, this message translates to:
  /// **'Oui, ajouter au stock'**
  String get yes_add_stock;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @not_in_inventory.
  ///
  /// In fr, this message translates to:
  /// **'Médicament non trouvé dans l\'inventaire.'**
  String get not_in_inventory;

  /// No description provided for @add_first.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez-le d\'abord.'**
  String get add_first;

  /// No description provided for @medication_recognized.
  ///
  /// In fr, this message translates to:
  /// **'Médicament reconnu'**
  String get medication_recognized;

  /// No description provided for @api_error_hint.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer le nom. Vous pouvez le saisir manuellement.'**
  String get api_error_hint;

  /// No description provided for @expired.
  ///
  /// In fr, this message translates to:
  /// **'Périmé'**
  String get expired;

  /// No description provided for @expires_in.
  ///
  /// In fr, this message translates to:
  /// **'Expire dans'**
  String get expires_in;

  /// No description provided for @days.
  ///
  /// In fr, this message translates to:
  /// **'j'**
  String get days;

  /// No description provided for @no_alerts.
  ///
  /// In fr, this message translates to:
  /// **'Aucune alerte'**
  String get no_alerts;

  /// No description provided for @no_alerts_hint.
  ///
  /// In fr, this message translates to:
  /// **'Vos stocks et dates sont OK'**
  String get no_alerts_hint;

  /// No description provided for @add_to_shopping_list.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la liste de courses'**
  String get add_to_shopping_list;

  /// No description provided for @detail.
  ///
  /// In fr, this message translates to:
  /// **'Détail'**
  String get detail;

  /// No description provided for @take_one.
  ///
  /// In fr, this message translates to:
  /// **'J\'en prends un'**
  String get take_one;

  /// No description provided for @take_quantity.
  ///
  /// In fr, this message translates to:
  /// **'Prendre'**
  String get take_quantity;

  /// No description provided for @remove_quantity.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove_quantity;

  /// No description provided for @add_stock.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au stock'**
  String get add_stock;

  /// No description provided for @view_notice.
  ///
  /// In fr, this message translates to:
  /// **'Voir la notice'**
  String get view_notice;

  /// No description provided for @expiry.
  ///
  /// In fr, this message translates to:
  /// **'Péremption'**
  String get expiry;

  /// No description provided for @reminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get reminder;

  /// No description provided for @daily_reminder.
  ///
  /// In fr, this message translates to:
  /// **'Rappel quotidien'**
  String get daily_reminder;

  /// No description provided for @not_set.
  ///
  /// In fr, this message translates to:
  /// **'Non défini'**
  String get not_set;

  /// No description provided for @at.
  ///
  /// In fr, this message translates to:
  /// **'À'**
  String get at;

  /// No description provided for @movement_history.
  ///
  /// In fr, this message translates to:
  /// **'Historique des mouvements'**
  String get movement_history;

  /// No description provided for @taken.
  ///
  /// In fr, this message translates to:
  /// **'Pris'**
  String get taken;

  /// No description provided for @added.
  ///
  /// In fr, this message translates to:
  /// **'Ajout'**
  String get added;

  /// No description provided for @add_medication_title.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un médicament'**
  String get add_medication_title;

  /// No description provided for @edit_medication_title.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le médicament'**
  String get edit_medication_title;

  /// No description provided for @medication_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom du médicament'**
  String get medication_name;

  /// No description provided for @medication_name_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Doliprane 1000mg'**
  String get medication_name_hint;

  /// No description provided for @add_photo.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get add_photo;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantity;

  /// No description provided for @unit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get unit;

  /// No description provided for @quantity_per_unit.
  ///
  /// In fr, this message translates to:
  /// **'Quantité par unité (optionnel)'**
  String get quantity_per_unit;

  /// No description provided for @quantity_per_unit_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 30 comprimés par plaquette'**
  String get quantity_per_unit_hint;

  /// No description provided for @place_storage.
  ///
  /// In fr, this message translates to:
  /// **'Lieu de rangement (optionnel)'**
  String get place_storage;

  /// No description provided for @place_storage_hint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Armoire salle de bain'**
  String get place_storage_hint;

  /// No description provided for @alert_stock_min.
  ///
  /// In fr, this message translates to:
  /// **'Alerte stock (quantité min)'**
  String get alert_stock_min;

  /// No description provided for @alert_stock_hint.
  ///
  /// In fr, this message translates to:
  /// **'0 = désactivé'**
  String get alert_stock_hint;

  /// No description provided for @expiry_date.
  ///
  /// In fr, this message translates to:
  /// **'Date de péremption (optionnel)'**
  String get expiry_date;

  /// No description provided for @expiry_optional.
  ///
  /// In fr, this message translates to:
  /// **'Péremption'**
  String get expiry_optional;

  /// No description provided for @remove_date.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la date'**
  String get remove_date;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get required;

  /// No description provided for @number_min.
  ///
  /// In fr, this message translates to:
  /// **'Nombre ≥ 0'**
  String get number_min;

  /// No description provided for @delete_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete_confirm;

  /// No description provided for @delete_medication_confirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce médicament de l\'inventaire ?'**
  String get delete_medication_confirm;

  /// No description provided for @first_day_of_week.
  ///
  /// In fr, this message translates to:
  /// **'Premier jour de la semaine'**
  String get first_day_of_week;

  /// No description provided for @sunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get monday;

  /// No description provided for @scan_sound.
  ///
  /// In fr, this message translates to:
  /// **'Son au scan'**
  String get scan_sound;

  /// No description provided for @family.
  ///
  /// In fr, this message translates to:
  /// **'Famille'**
  String get family;

  /// No description provided for @places.
  ///
  /// In fr, this message translates to:
  /// **'Lieux'**
  String get places;

  /// No description provided for @health.
  ///
  /// In fr, this message translates to:
  /// **'Santé'**
  String get health;

  /// No description provided for @allergies.
  ///
  /// In fr, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @backup_restore.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde / Restauration'**
  String get backup_restore;

  /// No description provided for @backup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder mes données'**
  String get backup;

  /// No description provided for @restore.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer'**
  String get restore;

  /// No description provided for @restore_warning.
  ///
  /// In fr, this message translates to:
  /// **'Écrasera les données actuelles.'**
  String get restore_warning;

  /// No description provided for @backup_success.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée'**
  String get backup_success;

  /// No description provided for @restore_success.
  ///
  /// In fr, this message translates to:
  /// **'Données restaurées'**
  String get restore_success;

  /// No description provided for @export_pdf_doctor.
  ///
  /// In fr, this message translates to:
  /// **'Exporter en PDF pour le médecin'**
  String get export_pdf_doctor;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @onboarding_title1.
  ///
  /// In fr, this message translates to:
  /// **'Scannez vos médicaments'**
  String get onboarding_title1;

  /// No description provided for @onboarding_body1.
  ///
  /// In fr, this message translates to:
  /// **'Scannez le code-barres ou Data Matrix sur la boîte pour ajouter un médicament à l\'inventaire.'**
  String get onboarding_body1;

  /// No description provided for @onboarding_title2.
  ///
  /// In fr, this message translates to:
  /// **'Retirez du stock'**
  String get onboarding_title2;

  /// No description provided for @onboarding_body2.
  ///
  /// In fr, this message translates to:
  /// **'Quand vous prenez un médicament, enregistrez la prise en un tap ou en scannant à nouveau.'**
  String get onboarding_body2;

  /// No description provided for @onboarding_title3.
  ///
  /// In fr, this message translates to:
  /// **'Consultez les alertes'**
  String get onboarding_title3;

  /// No description provided for @onboarding_body3.
  ///
  /// In fr, this message translates to:
  /// **'Restez informé des stocks faibles et des dates de péremption.'**
  String get onboarding_body3;

  /// No description provided for @onboarding_title4.
  ///
  /// In fr, this message translates to:
  /// **'Famille et lieux'**
  String get onboarding_title4;

  /// No description provided for @onboarding_body4.
  ///
  /// In fr, this message translates to:
  /// **'Organisez vos médicaments par personne et par lieu de rangement dans les réglages.'**
  String get onboarding_body4;

  /// No description provided for @get_started.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get get_started;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @shopping_add_from_alerts.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter depuis les alertes'**
  String get shopping_add_from_alerts;

  /// No description provided for @shopping_add_item.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un article'**
  String get shopping_add_item;

  /// No description provided for @shopping_share_list.
  ///
  /// In fr, this message translates to:
  /// **'Partager la liste'**
  String get shopping_share_list;

  /// No description provided for @shopping_empty.
  ///
  /// In fr, this message translates to:
  /// **'Liste vide'**
  String get shopping_empty;

  /// No description provided for @shopping_list_updated.
  ///
  /// In fr, this message translates to:
  /// **'Liste mise à jour'**
  String get shopping_list_updated;

  /// No description provided for @stats_pastes_7.
  ///
  /// In fr, this message translates to:
  /// **'Prises (7 jours)'**
  String get stats_pastes_7;

  /// No description provided for @stats_pastes_30.
  ///
  /// In fr, this message translates to:
  /// **'Prises (30 jours)'**
  String get stats_pastes_30;

  /// No description provided for @stats_most_used.
  ///
  /// In fr, this message translates to:
  /// **'Plus consommés'**
  String get stats_most_used;

  /// No description provided for @check_with_doctor.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier avec votre médecin ou pharmacien.'**
  String get check_with_doctor;

  /// No description provided for @sign_in.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get sign_in;

  /// No description provided for @sign_out.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get sign_out;

  /// No description provided for @account_synced.
  ///
  /// In fr, this message translates to:
  /// **'Foyer synchronisé'**
  String get account_synced;

  /// No description provided for @local_mode_title.
  ///
  /// In fr, this message translates to:
  /// **'Connexion / Synchronisation'**
  String get local_mode_title;

  /// No description provided for @local_mode_message.
  ///
  /// In fr, this message translates to:
  /// **'L\'application fonctionne en mode local. Pour vous connecter et synchroniser vos données avec un compte, configurez Supabase : créez un fichier .env à la racine du projet avec SUPABASE_URL et SUPABASE_ANON_KEY (voir .env.example), puis redémarrez l\'application.'**
  String get local_mode_message;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
