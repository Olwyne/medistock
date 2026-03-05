# MediStock

Application de gestion de stock de médicaments : inventaire, alertes, listes de courses, rappels. Comptes utilisateur et partage des données par foyer (famille) via Supabase.

## Prérequis

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable)
- Un compte [Supabase](https://supabase.com) (pour l’auth et la base de données)
- Optionnel : Docker si vous exécutez les commandes dans un conteneur

## Configuration

### 1. Variables d’environnement

Copiez le fichier d’exemple et renseignez vos clés Supabase :

```bash
cp .env.example .env
```

Éditez `.env` et remplacez par les valeurs de votre projet Supabase (Dashboard → Settings → API) :

- `SUPABASE_URL` : URL du projet (ex. `https://xxxx.supabase.co`)
- `SUPABASE_ANON_KEY` : clé anon (publique)

**Pour le build web (prod / Netlify)** : les variables ne sont pas lues depuis `.env` au runtime. Il faut les injecter au build avec `--dart-define` (voir section Déploiement Netlify).

**Optionnel (mobile)** : pour charger `.env` au démarrage, ajoutez dans `pubspec.yaml` sous `flutter:` la ligne `assets: ['.env']` et créez le fichier `.env` à la racine. Sans `.env`, l’app tourne en mode local sans Supabase.

### 2. Schéma Supabase

1. Créez un projet sur [Supabase](https://app.supabase.com).
2. Dans le projet : **SQL Editor** → **New query**.
3. Copiez-collez le contenu du fichier **`supabase/schema.sql`** du repo.
4. Exécutez la requête (Run).

Le schéma crée les tables (families, family_users, household_members, medications, stock_movements, places, shopping_items, user_allergies) et les politiques RLS pour que chaque foyer ne voie que ses données.

## Installation

```bash
flutter pub get
```

## Lancement

- **Mobile** : `flutter run` (ou via Docker si vous utilisez un conteneur)
- **Web** : `flutter run -d chrome`

Au premier lancement avec Supabase configuré : connexion ou inscription, puis création ou rejoindre un foyer. Ensuite l’app affiche l’inventaire et les écrans habituels.

## Build web / PWA

Build de production (remplacez par vos vraies valeurs ou variables d’environnement) :

```bash
flutter build web --release \
  --dart-define=SUPABASE_URL=https://votre-projet.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=votre_cle_anon
```

La sortie est dans **`build/web`**. L’app web est une PWA (manifest et service worker générés par Flutter) : installable en mode standalone.

## Déploiement Netlify

Deux possibilités :

### Option 1 : Build local puis déploiement

1. En local, exécutez :
   ```bash
   flutter build web --release \
     --dart-define=SUPABASE_URL=$SUPABASE_URL \
     --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
   ```
2. Dans [Netlify](https://app.netlify.com) : **Sites** → **Add new site** → **Deploy manually** (ou **Drag and drop**).
3. Déposez le dossier **`build/web`** (contenu du dossier, pas le dossier lui-même).
4. Ou via CLI : `netlify deploy --dir=build/web --prod`.

Les redirects SPA (`/*` → `/index.html`) sont définis dans **`netlify.toml`** ; si vous déployez uniquement `build/web`, créez un fichier **`_redirects`** dans `build/web` avec la ligne : `/* /index.html 200`.

### Option 2 : Build sur Netlify

L’image Netlify par défaut n’inclut pas Flutter. Il faut soit une image personnalisée avec le SDK Flutter, soit un buildpack/plugin. Dans ce cas :

1. **Site settings** → **Environment variables** : ajoutez `SUPABASE_URL` et `SUPABASE_ANON_KEY`.
2. Dans **`netlify.toml`**, configurez la **build command** pour installer Flutter (ou utiliser une image qui l’inclut) puis lancer :
   ```bash
   flutter build web --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
   ```
3. **Publish directory** : `build/web`.

Le fichier **`netlify.toml`** à la racine du repo contient déjà `publish = "build/web"` et les redirects SPA.

## Résumé des fichiers

| Fichier / dossier      | Rôle |
|------------------------|------|
| `supabase/schema.sql`  | Schéma SQL à exécuter dans Supabase (tables + RLS) |
| `.env`                 | Variables Supabase (non versionné ; copier depuis `.env.example`) |
| `netlify.toml`         | Config Netlify (publish, redirects) |
| `web/manifest.json`    | Manifest PWA |
| `web/index.html`       | Point d’entrée web, meta PWA |

## Licence

Projet personnel / éducatif. À adapter selon votre usage.
