# AGENTS.md — MediStock

Directives pour les agents IA travaillant sur ce projet Flutter.

## Vue d'ensemble

MediStock est une application Flutter de suivi de médicaments à domicile. Elle permet de scanner des médicaments (codes CIP/GS1), suivre les stocks, gérer les dates de péremption, planifier des rappels de prise et synchroniser les données en famille via Supabase.

**Stack** : Flutter 3.x · Dart 3.11+ · SQLite (sqflite) · Supabase · Provider · Material 3

---

## Structure du projet

```
lib/
├── core/           # Configuration (env_config.dart)
├── data/           # Base SQLite (database.dart, version 7)
├── models/         # Entités : Medication, StockMovement, FamilyMember, Place, ShoppingItem
├── providers/      # State management (Provider) : auth, medication, family, shopping, theme, locale, settings
├── repositories/   # Accès données : medication_repository.dart
├── screens/        # UI : inventaire, scan, alertes, shopping, settings, stats, onboarding…
├── services/       # Logique métier : scan, API BDPM, sync Supabase, rappels, backup, PDF, interactions
└── l10n/           # Internationalisation FR/EN (fichiers .arb + generated/)
```

---

## Règles importantes

### Double mode local / cloud
L'app fonctionne **sans compte** (SQLite local) ou **avec compte Supabase** (sync famille).
- Sur **mobile** : SQLite est la source de vérité. Supabase est synchronisé via `SyncService.pull()` au démarrage.
- Sur **web** : pas de SQLite. Toutes les lectures/écritures passent directement par Supabase.
- Vérifier `kIsWeb` et `EnvConfig.isConfigured` avant tout accès base de données.
- Ne jamais appeler `AppDatabase.database` depuis du code web.

### Identifiants double clé
Les médicaments ont deux identifiants :
- `id` (int) : clé SQLite locale, uniquement sur mobile.
- `serverId` (String, UUID) : clé Supabase, présente si l'utilisateur est connecté.

Toujours gérer les deux cas. Sur web, utiliser `serverId` pour identifier un médicament.

### Sync Supabase
`SyncService.pull()` effectue un **pull complet** (efface + recharge). Ne pas appeler cette méthode inutilement. Elle mappe les UUIDs distants vers les IDs locaux (voir `remoteToLocalMed` / `remoteToLocalMember`).

### Famille courante
L'identifiant de famille (`familyId` : String UUID) est stocké dans `SharedPreferences` via `AuthService`. Le passer explicitement aux méthodes de repository et de sync plutôt que de le lire globalement.

### Providers
- `MedicationProvider` est la façade principale pour l'UI. Ne pas accéder à `MedicationRepository` ou `SyncService` directement depuis les screens.
- `AuthProvider` expose `currentFamilyId`, `isSignedIn`, `isConfigured`. Les autres providers en dépendent.

---

## Conventions

- **Langue** : code en anglais, commentaires et textes UI en français.
- **Localisation** : tout texte affiché à l'utilisateur doit passer par `AppLocalizations.of(context)`. Ne pas coder de chaînes en dur dans les widgets.
- **Unités** : utiliser `MedicationUnits.all` pour la liste des unités valides. Ne pas créer de nouvelles constantes d'unité ailleurs.
- **Alertes** : la logique de détection (périmé, bientôt périmé, stock faible) est dans le modèle `Medication` (`estPerime`, `estBientotPerime`, `stockFaible`) et exposée via les getters de `MedicationProvider`. Ne pas la dupliquer dans les screens.
- **Migrations SQLite** : toute modification du schéma doit incrémenter `_version` dans `database.dart` et ajouter un bloc dans `_onUpgrade`. Ne jamais modifier `_onCreate` rétroactivement.

---

## API BDPM

- Endpoint : `https://medicaments-api.giygas.dev/v1/medicaments?cip=<code>`
- Codes supportés : CIP7 (7 chiffres), CIP13 (13 chiffres).
- Timeout : 8 secondes. Gérer les cas `timeout`, `rateLimit` (429), `server` (5xx) via `ApiErrorType`.
- Le parsing du libellé de présentation est dans `MedicationApiService.parsePresentationLibelle()` — méthode publique, couverte par des tests.

---

## Tests

```
test/
├── medication_alert_test.dart       # Tests unitaires des getters d'alerte du modèle
└── medication_api_service_test.dart # Tests de parsePresentationLibelle
```

- Lancer les tests : `flutter test`
- Toute nouvelle logique métier dans `models/` ou `services/` doit être accompagnée de tests unitaires.
- Pas de tests de widgets en place actuellement — contributions bienvenues.

---

## Points d'attention connus

- **Photos non synchronisées** : `photo_path` est un chemin local. Les photos ne sont pas uploadées sur Supabase. Ne pas promettre de sync de photos sans implémenter l'upload (ex: Supabase Storage).
- **Rappels** : un seul rappel par médicament. `ReminderService.scheduleReminder()` écrase le rappel existant.
- **Sync incrémentale absente** : `SyncService.pull()` recharge toutes les données. Sur de gros inventaires, préférer un pull conditionnel (timestamp).
- **Interactions médicamenteuses** : `InteractionsService` fait un simple match de chaîne sur les allergies enregistrées. Ce n'est pas un vrai contrôle d'interactions.
