# Architecture - Application Gestion Atelier Menuiserie

## Vue d'ensemble
Application mobile Flutter pour la gestion des approvisionnements avec génération Excel et tableau de bord analytique.

## Fonctionnalités principales

### 1. Formulaire d'achat
- Sélection date (calendrier)
- Propriétaire (CET/Cabrel/Joseph/Marcel/Aurélien/Autre)
- Type projet (Interne/Client/Mixte)
- Articles prédéfinis (BOIS/Peinture/Diluant/Colle/Autre)
- Prix automatique + possibilité modification
- Quantité et calcul total
- Mode paiement (Espèces/OM/Momo/Autre)
- Fournisseur (AGOGO/AHIDJO/AUTRE)
- Commentaires

### 2. Tableau de bord
- Statistiques fournisseurs principaux
- Analyses des dépenses par projet
- Graphiques des tendances
- Métriques clés

### 3. Génération Excel
- Export automatique de tous les achats
- Colonnes: Date, Propriétaire, Type projet, Article, Quantité, Prix unitaire, Total, Paiement, Fournisseur, Commentaires

### 4. Stockage hors ligne
- Base SQLite locale
- Synchronisation des données
- Historique complet

## Structure technique

### Modèles de données
- Purchase (Achat)
- Article (avec prix prédéfinis)
- Supplier (Fournisseur)
- Owner (Propriétaire)

### Services
- DatabaseService (SQLite)
- ExcelService (génération)
- AnalyticsService (calculs)

### Écrans
- HomePage (navigation)
- DashboardScreen (tableau de bord)
- PurchaseFormScreen (formulaire)
- HistoryScreen (historique)

### Architecture
- Pattern Provider pour state management
- Services pattern pour logique métier
- Repository pattern pour données

## Technologies
- Flutter (cross-platform)
- SQLite (stockage local)
- Excel generation
- Charts pour graphiques
- Material Design 3