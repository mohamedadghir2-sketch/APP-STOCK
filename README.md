# Stock Chaussures — application Android (Flutter + SQLite)

Gestion de stock de chaussures, **100 % hors ligne**. Toutes les données et les
photos restent sur le téléphone : aucune connexion, aucun compte.

## 1. Installation (5 minutes)

Prérequis : Flutter **3.22 ou plus récent** et Android Studio (SDK Android).

```bash
# 1. Se placer dans le dossier du projet
cd stock_chaussures

# 2. Générer les dossiers natifs Android (ios/, android/, etc.)
#    Le fichier android/app/src/main/AndroidManifest.xml fourni ici est
#    conservé : répondez « n » si Flutter propose de l'écraser, ou
#    recopiez-le après la commande.
flutter create . --project-name stock_chaussures --platforms android

# 3. Installer les dépendances
flutter pub get

# 4. Lancer sur un téléphone branché en USB (débogage activé)
flutter run

# 5. Générer l'APK d'installation
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

Dans `android/app/build.gradle`, vérifiez `minSdkVersion 21` (requis par
`image_picker`). Avec Flutter récent, la valeur par défaut convient déjà.

## 2. Ce que fait l'application

| Fonctionnalité | Où |
|---|---|
| Ajouter / modifier / supprimer une chaussure | `screens/shoe_form_screen.dart`, `screens/shoe_detail_screen.dart` |
| Photo depuis l'appareil photo **ou** la galerie | `utils/photo_storage.dart` |
| Liste complète du stock | `screens/stock_view.dart` |
| Recherche libre (marque, modèle, couleur, pointure) | `data/database_helper.dart` → `fetchShoes` |
| Filtres cumulables + 6 tris | `widgets/filter_sheet.dart` |
| Quantité restante par modèle | badge `QuantityPill`, + / − sur la fiche |
| Valeur du stock et bénéfice potentiel | `widgets/summary_card.dart`, `screens/stats_view.dart` |
| Alerte stock faible / rupture | seuil `kLowStockThreshold` |

### Calculs

Pour chaque référence :

- **Valeur du stock** = prix d'achat × quantité
- **Vente potentielle** = prix de vente × quantité
- **Bénéfice potentiel** = (prix de vente − prix d'achat) × quantité
- **Taux de marge** = bénéfice ÷ prix d'achat × 100

Les totaux sont calculés directement en SQL (`SUM(quantity * purchase_price)`…),
donc instantanés même avec plusieurs milliers de références.

## 3. Structure du code

```
lib/
├─ main.dart                     Démarrage, thème, localisation fr_FR
├─ data/
│  └─ database_helper.dart       SQLite : schéma, CRUD, recherche, agrégats
├─ models/
│  ├─ shoe.dart                  Une référence + calculs financiers
│  ├─ shoe_filter.dart           Recherche, filtres, tri
│  └─ stock_summary.dart         Totaux du stock, stats par marque
├─ providers/
│  └─ shoe_provider.dart         État de l'écran (Provider / ChangeNotifier)
├─ screens/
│  ├─ root_screen.dart           Onglets Stock / Statistiques + bouton Ajouter
│  ├─ stock_view.dart            Liste, recherche, filtres actifs
│  ├─ stats_view.dart            Indicateurs, marques, réapprovisionnement
│  ├─ shoe_detail_screen.dart    Fiche produit, ajustement rapide, suppression
│  └─ shoe_form_screen.dart      Création / modification, aperçu des marges
├─ widgets/                      Carte produit, synthèse, filtres, photo, vide
├─ theme/app_theme.dart          Material 3, clair + sombre
└─ utils/                        Formats, constantes, stockage des photos
```

### Base de données

Table `shoes` (SQLite, fichier `stock_chaussures.db`) :

| Colonne | Type | Rôle |
|---|---|---|
| `id` | INTEGER PK | identifiant |
| `brand`, `model`, `color` | TEXT | marque, modèle, couleur |
| `size` | REAL | pointure (42 ou 42.5) |
| `quantity` | INTEGER | quantité restante |
| `purchase_price`, `sale_price` | REAL | prix d'achat / de vente |
| `photo` | TEXT | nom du fichier image |
| `note` | TEXT | note libre (facultatif) |
| `created_at`, `updated_at` | TEXT | dates ISO 8601 |

Index sur `brand`, `model`, `color` et `size` pour des filtres rapides.

Les photos ne sont pas stockées en base : le fichier est copié dans le dossier
privé de l'application (`.../app_flutter/photos/`) et seul son **nom** est
enregistré, ce qui évite les images cassées après une mise à jour.

Pour faire évoluer le schéma plus tard : incrémentez `_dbVersion` et complétez
`_onUpgrade` dans `database_helper.dart`.

## 4. Personnalisation rapide

| Envie | Fichier | Ligne |
|---|---|---|
| Changer la devise (DH, CHF, $…) | `utils/constants.dart` | `kCurrencySymbol` |
| Changer le seuil « stock faible » | `utils/constants.dart` | `kLowStockThreshold` |
| Changer la couleur de l'app | `theme/app_theme.dart` | `AppTheme.seed` |
| Ajouter des noms de couleurs reconnus (pastilles) | `utils/constants.dart` | `colorFromName` |
| Renommer l'application | `android/app/src/main/AndroidManifest.xml` | `android:label` |

## 5. Permissions Android

Le manifeste fourni déclare `CAMERA` et `READ_EXTERNAL_STORAGE`
(≤ Android 12). Sur Android 13+, la galerie passe par le sélecteur système :
aucune permission de stockage n'est demandée à l'utilisateur.

## 6. Pistes d'évolution

- Export CSV du stock et sauvegarde du fichier `.db`
- Historique des ventes (table `sales`) pour un vrai chiffre d'affaires réalisé
- Scan de code-barres pour retrouver une référence
- Étiquettes de pointures multiples pour un même modèle (regroupement)
