import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  String get _lang => locale.languageCode;

  String get homeTitle => _t('home_title');
  String get greeting => _t('greeting');
  String get watchSection => _t('watch_section');
  String get watchSectionHint => _t('watch_section_hint');
  String get upcomingExpiry => _t('upcoming_expiry');
  String get byPlace => _t('by_place');
  String get seeAll => _t('see_all');
  String get forWhom => _t('for_whom');
  String get household => _t('household');
  String get members => _t('members');
  String get addMember => _t('add_member');
  String get inviteSomeone => _t('invite_someone');
  String get leaveHousehold => _t('leave_household');
  String get goodToKnow => _t('good_to_know');
  String get goodToKnowHint => _t('good_to_know_hint');
  String get inStock => _t('in_stock');
  String get toReorder => _t('to_reorder');
  String get inventaireTitle => _t('inventaire_title');
  String get scannerTitle => _t('scanner_title');
  String get alertesTitle => _t('alertes_title');
  String get settingsTitle => _t('settings_title');
  String get shoppingTitle => _t('shopping_title');
  String get statsTitle => _t('stats_title');

  String get add => _t('add');
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get retry => _t('retry');

  String get theme => _t('theme');
  String get themeSystem => _t('theme_system');
  String get themeLight => _t('theme_light');
  String get themeDark => _t('theme_dark');
  String get sort => _t('sort');
  String get sortByName => _t('sort_by_name');
  String get sortByQuantity => _t('sort_by_quantity');
  String get sortByExpiry => _t('sort_by_expiry');
  String get filter => _t('filter');
  String get filterAll => _t('filter_all');
  String get filterSoonExpiry => _t('filter_soon_expiry');
  String get filterLowStock => _t('filter_low_stock');
  String get place => _t('place');
  String get exportCsv => _t('export_csv');
  String get exportCsvCopied => _t('export_csv_copied');
  String get searchHint => _t('search_hint');
  String get noMedication => _t('no_medication');
  String get noMedicationHint => _t('no_medication_hint');
  String get addMedication => _t('add_medication');
  String get medications => _t('medications');
  String get soonExpiry => _t('soon_expiry');
  String get lowStock => _t('low_stock');

  String get scanAddToStock => _t('scan_add_to_stock');
  String get scanRemoveFromStock => _t('scan_remove_from_stock');
  String get scanHintAdd => _t('scan_hint_add');
  String get scanHintRemove => _t('scan_hint_remove');
  String get medicationAdded => _t('medication_added');
  String get medicationRemoved => _t('medication_removed');
  String get addToInventory => _t('add_to_inventory');
  String get alreadyInInventory => _t('already_in_inventory');
  String get addToStockConfirm => _t('add_to_stock_confirm');
  String get yesAddStock => _t('yes_add_stock');
  String get no => _t('no');
  String get notInInventory => _t('not_in_inventory');
  String get addFirst => _t('add_first');
  String get medicationRecognized => _t('medication_recognized');
  String get apiErrorHint => _t('api_error_hint');

  String get expired => _t('expired');
  String get expiresIn => _t('expires_in');
  String get days => _t('days');
  String get noAlerts => _t('no_alerts');
  String get noAlertsHint => _t('no_alerts_hint');
  String get addToShoppingList => _t('add_to_shopping_list');

  String get detail => _t('detail');
  String get takeOne => _t('take_one');
  String get takeQuantity => _t('take_quantity');
  String get removeQuantity => _t('remove_quantity');
  String get addStock => _t('add_stock');
  String get viewNotice => _t('view_notice');
  String get expiry => _t('expiry');
  String get reminder => _t('reminder');
  String get dailyReminder => _t('daily_reminder');
  String get notSet => _t('not_set');
  String get at => _t('at');
  String get movementHistory => _t('movement_history');
  String get taken => _t('taken');
  String get added => _t('added');

  String get addMedicationTitle => _t('add_medication_title');
  String get editMedicationTitle => _t('edit_medication_title');
  String get medicationName => _t('medication_name');
  String get medicationNameHint => _t('medication_name_hint');
  String get addPhoto => _t('add_photo');
  String get quantity => _t('quantity');
  String get unit => _t('unit');
  String get quantityPerUnit => _t('quantity_per_unit');
  String get quantityPerUnitHint => _t('quantity_per_unit_hint');
  String get placeStorage => _t('place_storage');
  String get placeStorageHint => _t('place_storage_hint');
  String get alertStockMin => _t('alert_stock_min');
  String get alertStockHint => _t('alert_stock_hint');
  String get expiryDate => _t('expiry_date');
  String get expiryOptional => _t('expiry_optional');
  String get removeDate => _t('remove_date');
  String get required => _t('required');
  String get numberMin => _t('number_min');

  String get deleteConfirm => _t('delete_confirm');
  String get deleteMedicationConfirm => _t('delete_medication_confirm');

  String get firstDayOfWeek => _t('first_day_of_week');
  String get sunday => _t('sunday');
  String get monday => _t('monday');
  String get scanSound => _t('scan_sound');
  String get family => _t('family');
  String get places => _t('places');
  String get health => _t('health');
  String get allergies => _t('allergies');
  String get backupRestore => _t('backup_restore');
  String get backup => _t('backup');
  String get restore => _t('restore');
  String get restoreWarning => _t('restore_warning');
  String get backupSuccess => _t('backup_success');
  String get restoreSuccess => _t('restore_success');
  String get exportPdfDoctor => _t('export_pdf_doctor');
  String get language => _t('language');
  String get french => _t('french');
  String get english => _t('english');

  String get onboardingTitle1 => _t('onboarding_title1');
  String get onboardingBody1 => _t('onboarding_body1');
  String get onboardingTitle2 => _t('onboarding_title2');
  String get onboardingBody2 => _t('onboarding_body2');
  String get onboardingTitle3 => _t('onboarding_title3');
  String get onboardingBody3 => _t('onboarding_body3');
  String get onboardingTitle4 => _t('onboarding_title4');
  String get onboardingBody4 => _t('onboarding_body4');
  String get getStarted => _t('get_started');
  String get next => _t('next');

  String get shoppingAddFromAlerts => _t('shopping_add_from_alerts');
  String get shoppingAddItem => _t('shopping_add_item');
  String get shoppingShareList => _t('shopping_share_list');
  String get shoppingEmpty => _t('shopping_empty');
  String get shoppingListUpdated => _t('shopping_list_updated');

  String get statsPastes7 => _t('stats_pastes_7');
  String get statsPastes30 => _t('stats_pastes_30');
  String get statsMostUsed => _t('stats_most_used');

  String get checkWithDoctor => _t('check_with_doctor');

  String get signIn => _t('sign_in');
  String get signOut => _t('sign_out');
  String get accountSynced => _t('account_synced');

  String _t(String key) {
    return _strings[_lang]?[key] ?? _strings['fr']?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _strings = {
    'fr': {
      'home_title': 'Accueil',
      'greeting': 'Bonjour',
      'watch_section': 'À surveiller',
      'watch_section_hint': 'en un coup d\'œil',
      'upcoming_expiry': 'Prochaines péremptions',
      'by_place': 'Par lieu',
      'see_all': 'Tout voir',
      'for_whom': 'Pour qui ?',
      'household': 'Foyer',
      'members': 'Membres',
      'add_member': 'Ajouter un membre',
      'invite_someone': 'Inviter un proche',
      'leave_household': 'Quitter ce foyer',
      'good_to_know': 'Bon à savoir',
      'good_to_know_hint': 'Conservez ce médicament à l\'abri de la lumière et de l\'humidité. Tenir hors de portée des enfants.',
      'in_stock': 'En stock',
      'to_reorder': 'À racheter',
      'inventaire_title': 'Inventaire',
      'scanner_title': 'Scanner',
      'alertes_title': 'Alertes',
      'settings_title': 'Réglages',
      'shopping_title': 'Liste de courses',
      'stats_title': 'Statistiques',
      'add': 'Ajouter',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'retry': 'Réessayer',
      'theme': 'Thème',
      'theme_system': 'Système',
      'theme_light': 'Clair',
      'theme_dark': 'Sombre',
      'sort': 'Trier',
      'sort_by_name': 'Par nom',
      'sort_by_quantity': 'Par quantité',
      'sort_by_expiry': 'Par péremption',
      'filter': 'Filtrer',
      'filter_all': 'Tous',
      'filter_soon_expiry': 'Bientôt périmés',
      'filter_low_stock': 'Stock faible',
      'place': 'Lieu',
      'export_csv': 'Exporter en CSV',
      'export_csv_copied': 'Inventaire copié dans le presse-papier (CSV)',
      'search_hint': 'Rechercher (nom, lieu)...',
      'no_medication': 'Aucun médicament',
      'no_medication_hint': 'Scannez un code ou ajoutez manuellement',
      'add_medication': 'Ajouter un médicament',
      'medications': 'Médicaments',
      'soon_expiry': 'Bientôt périmés',
      'low_stock': 'Stock faible',
      'scan_add_to_stock': 'Ajouter au stock',
      'scan_remove_from_stock': 'Retirer du stock',
      'scan_hint_add': 'Scannez le code sur la boîte ou la plaquette',
      'scan_hint_remove': 'Scannez le code du médicament à retirer',
      'medication_added': 'Médicament ajouté à l\'inventaire',
      'medication_removed': '1 unité retirée',
      'add_to_inventory': 'Ajouter à l\'inventaire',
      'already_in_inventory': 'Ce médicament est déjà dans l\'inventaire. Voulez-vous ajouter une quantité au stock ?',
      'add_to_stock_confirm': 'Oui, ajouter au stock',
      'yes_add_stock': 'Oui, ajouter au stock',
      'no': 'Non',
      'not_in_inventory': 'Médicament non trouvé dans l\'inventaire.',
      'add_first': 'Ajoutez-le d\'abord.',
      'medication_recognized': 'Médicament reconnu',
      'api_error_hint': 'Impossible de récupérer le nom. Vous pouvez le saisir manuellement.',
      'expired': 'Périmé',
      'expires_in': 'Expire dans',
      'days': 'j',
      'no_alerts': 'Aucune alerte',
      'no_alerts_hint': 'Vos stocks et dates sont OK',
      'add_to_shopping_list': 'Ajouter à la liste de courses',
      'detail': 'Détail',
      'take_one': 'J\'en prends un',
      'take_quantity': 'Prendre',
      'remove_quantity': 'Retirer',
      'add_stock': 'Ajouter au stock',
      'view_notice': 'Voir la notice',
      'expiry': 'Péremption',
      'reminder': 'Rappel quotidien',
      'daily_reminder': 'Rappel quotidien',
      'not_set': 'Non défini',
      'at': 'À',
      'movement_history': 'Historique des mouvements',
      'taken': 'Pris',
      'added': 'Ajout',
      'add_medication_title': 'Ajouter un médicament',
      'edit_medication_title': 'Modifier le médicament',
      'medication_name': 'Nom du médicament',
      'medication_name_hint': 'Ex: Doliprane 1000mg',
      'add_photo': 'Ajouter une photo',
      'quantity': 'Quantité',
      'unit': 'Unité',
      'quantity_per_unit': 'Quantité par unité (optionnel)',
      'quantity_per_unit_hint': 'Ex: 30 comprimés par plaquette',
      'place_storage': 'Lieu de rangement (optionnel)',
      'place_storage_hint': 'Ex: Armoire salle de bain',
      'alert_stock_min': 'Alerte stock (quantité min)',
      'alert_stock_hint': '0 = désactivé',
      'expiry_date': 'Date de péremption (optionnel)',
      'expiry_optional': 'Péremption',
      'remove_date': 'Supprimer la date',
      'required': 'Obligatoire',
      'number_min': 'Nombre ≥ 0',
      'delete_confirm': 'Supprimer',
      'delete_medication_confirm': 'Supprimer ce médicament de l\'inventaire ?',
      'first_day_of_week': 'Premier jour de la semaine',
      'sunday': 'Dimanche',
      'monday': 'Lundi',
      'scan_sound': 'Son au scan',
      'family': 'Famille',
      'places': 'Lieux',
      'health': 'Santé',
      'allergies': 'Allergies',
      'backup_restore': 'Sauvegarde / Restauration',
      'backup': 'Sauvegarder mes données',
      'restore': 'Restaurer',
      'restore_warning': 'Écrasera les données actuelles.',
      'backup_success': 'Sauvegarde créée',
      'restore_success': 'Données restaurées',
      'export_pdf_doctor': 'Exporter en PDF pour le médecin',
      'language': 'Langue',
      'french': 'Français',
      'english': 'English',
      'onboarding_title1': 'Scannez vos médicaments',
      'onboarding_body1': 'Scannez le code-barres ou Data Matrix sur la boîte pour ajouter un médicament à l\'inventaire.',
      'onboarding_title2': 'Retirez du stock',
      'onboarding_body2': 'Quand vous prenez un médicament, enregistrez la prise en un tap ou en scannant à nouveau.',
      'onboarding_title3': 'Consultez les alertes',
      'onboarding_body3': 'Restez informé des stocks faibles et des dates de péremption.',
      'onboarding_title4': 'Famille et lieux',
      'onboarding_body4': 'Organisez vos médicaments par personne et par lieu de rangement dans les réglages.',
      'get_started': 'Commencer',
      'next': 'Suivant',
      'shopping_add_from_alerts': 'Ajouter depuis les alertes',
      'shopping_add_item': 'Ajouter un article',
      'shopping_share_list': 'Partager la liste',
      'shopping_empty': 'Liste vide',
      'shopping_list_updated': 'Liste mise à jour',
      'stats_pastes_7': 'Prises (7 jours)',
      'stats_pastes_30': 'Prises (30 jours)',
      'stats_most_used': 'Plus consommés',
      'check_with_doctor': 'Vérifier avec votre médecin ou pharmacien.',
      'sign_in': 'Se connecter',
      'sign_out': 'Déconnexion',
      'account_synced': 'Foyer synchronisé',
    },
    'en': {
      'home_title': 'Home',
      'greeting': 'Hello',
      'watch_section': 'To watch',
      'watch_section_hint': 'at a glance',
      'upcoming_expiry': 'Upcoming expiries',
      'by_place': 'By place',
      'see_all': 'See all',
      'for_whom': 'For whom?',
      'household': 'Household',
      'members': 'Members',
      'add_member': 'Add a member',
      'invite_someone': 'Invite someone',
      'leave_household': 'Leave this household',
      'good_to_know': 'Good to know',
      'good_to_know_hint': 'Store this medication away from light and humidity. Keep out of reach of children.',
      'in_stock': 'In stock',
      'to_reorder': 'To reorder',
      'inventaire_title': 'Inventory',
      'scanner_title': 'Scan',
      'alertes_title': 'Alerts',
      'settings_title': 'Settings',
      'shopping_title': 'Shopping list',
      'stats_title': 'Statistics',
      'add': 'Add',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'retry': 'Retry',
      'theme': 'Theme',
      'theme_system': 'System',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'sort': 'Sort',
      'sort_by_name': 'By name',
      'sort_by_quantity': 'By quantity',
      'sort_by_expiry': 'By expiry',
      'filter': 'Filter',
      'filter_all': 'All',
      'filter_soon_expiry': 'Soon expired',
      'filter_low_stock': 'Low stock',
      'place': 'Place',
      'export_csv': 'Export CSV',
      'export_csv_copied': 'Inventory copied to clipboard (CSV)',
      'search_hint': 'Search (name, place)...',
      'no_medication': 'No medication',
      'no_medication_hint': 'Scan a code or add manually',
      'add_medication': 'Add a medication',
      'medications': 'Medications',
      'soon_expiry': 'Soon expired',
      'low_stock': 'Low stock',
      'scan_add_to_stock': 'Add to stock',
      'scan_remove_from_stock': 'Remove from stock',
      'scan_hint_add': 'Scan the code on the box or blister',
      'scan_hint_remove': 'Scan the code of the medication to remove',
      'medication_added': 'Medication added to inventory',
      'medication_removed': '1 unit removed',
      'add_to_inventory': 'Add to inventory',
      'already_in_inventory': 'This medication is already in inventory. Add quantity to stock?',
      'add_to_stock_confirm': 'Yes, add to stock',
      'yes_add_stock': 'Yes, add to stock',
      'no': 'No',
      'not_in_inventory': 'Medication not found in inventory.',
      'add_first': 'Add it first.',
      'medication_recognized': 'Medication recognized',
      'api_error_hint': 'Could not fetch name. You can enter it manually.',
      'expired': 'Expired',
      'expires_in': 'Expires in',
      'days': 'd',
      'no_alerts': 'No alerts',
      'no_alerts_hint': 'Your stocks and dates are OK',
      'add_to_shopping_list': 'Add to shopping list',
      'detail': 'Detail',
      'take_one': 'I\'m taking one',
      'take_quantity': 'Take',
      'remove_quantity': 'Remove',
      'add_stock': 'Add to stock',
      'view_notice': 'View leaflet',
      'expiry': 'Expiry',
      'reminder': 'Daily reminder',
      'daily_reminder': 'Daily reminder',
      'not_set': 'Not set',
      'at': 'At',
      'movement_history': 'Movement history',
      'taken': 'Taken',
      'added': 'Added',
      'add_medication_title': 'Add a medication',
      'edit_medication_title': 'Edit medication',
      'medication_name': 'Medication name',
      'medication_name_hint': 'E.g. Paracetamol 1000mg',
      'add_photo': 'Add photo',
      'quantity': 'Quantity',
      'unit': 'Unit',
      'quantity_per_unit': 'Quantity per unit (optional)',
      'quantity_per_unit_hint': 'E.g. 30 tablets per blister',
      'place_storage': 'Storage place (optional)',
      'place_storage_hint': 'E.g. Bathroom cabinet',
      'alert_stock_min': 'Low stock alert (min quantity)',
      'alert_stock_hint': '0 = disabled',
      'expiry_date': 'Expiry date (optional)',
      'expiry_optional': 'Expiry',
      'remove_date': 'Remove date',
      'required': 'Required',
      'number_min': 'Number ≥ 0',
      'delete_confirm': 'Delete',
      'delete_medication_confirm': 'Delete this medication from inventory?',
      'first_day_of_week': 'First day of week',
      'sunday': 'Sunday',
      'monday': 'Monday',
      'scan_sound': 'Scan sound',
      'family': 'Family',
      'places': 'Places',
      'health': 'Health',
      'allergies': 'Allergies',
      'backup_restore': 'Backup / Restore',
      'backup': 'Backup my data',
      'restore': 'Restore',
      'restore_warning': 'This will overwrite current data.',
      'backup_success': 'Backup created',
      'restore_success': 'Data restored',
      'export_pdf_doctor': 'Export PDF for doctor',
      'language': 'Language',
      'french': 'Français',
      'english': 'English',
      'onboarding_title1': 'Scan your medications',
      'onboarding_body1': 'Scan the barcode or Data Matrix on the box to add a medication to your inventory.',
      'onboarding_title2': 'Remove from stock',
      'onboarding_body2': 'When you take a medication, record it with one tap or by scanning again.',
      'onboarding_title3': 'Check alerts',
      'onboarding_body3': 'Stay informed about low stock and expiry dates.',
      'onboarding_title4': 'Family and places',
      'onboarding_body4': 'Organize medications by person and storage place in settings.',
      'get_started': 'Get started',
      'next': 'Next',
      'shopping_add_from_alerts': 'Add from alerts',
      'shopping_add_item': 'Add item',
      'shopping_share_list': 'Share list',
      'shopping_empty': 'List empty',
      'shopping_list_updated': 'List updated',
      'stats_pastes_7': 'Taken (7 days)',
      'stats_pastes_30': 'Taken (30 days)',
      'stats_most_used': 'Most used',
      'check_with_doctor': 'Check with your doctor or pharmacist.',
      'sign_in': 'Sign in',
      'sign_out': 'Sign out',
      'account_synced': 'Family synced',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
