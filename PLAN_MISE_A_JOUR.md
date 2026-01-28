# ShareMyBag — Plan de Mise à Jour International

## Vision

**ShareMyBag** est une plateforme P2P disruptive permettant aux voyageurs de **monétiser leurs kilos de bagages inutilisés** en les mettant à disposition de personnes souhaitant envoyer des colis. Le modèle repose sur un **système d'enchères inversées** : l'expéditeur publie son besoin, les voyageurs font des offres.

---

## PHASE 1 — SÉCURISATION CRITIQUE (Sprint 1)

### Epic 1.1 : Élimination des failles de sécurité critiques

**US-1.1.1** — En tant qu'opérateur, je veux que tous les secrets (clés API, credentials DB, OAuth) soient stockés dans des variables d'environnement et jamais dans le code source, afin d'empêcher toute fuite de credentials.
- **Critères d'acceptation :**
  - [ ] Fichier `config/database.yml` utilise `ENV[]` pour tous les credentials
  - [ ] Fichier `config/initializers/omniauth.rb` utilise `ENV[]` pour toutes les clés OAuth
  - [ ] Fichier `config/secrets.yml` utilise `ENV[]` pour le secret_key_base
  - [ ] Fichier `.gitpod.yml` ne contient plus de mots de passe en dur
  - [ ] Fichier `config/application.yml.example` créé comme template Figaro
  - [ ] `.gitignore` mis à jour pour exclure `config/application.yml` et `config/secrets.yml`

**US-1.1.2** — En tant qu'opérateur, je veux que SSL/TLS soit forcé en production, afin que toutes les communications soient chiffrées.
- **Critères d'acceptation :**
  - [ ] `config.force_ssl = true` activé dans `production.rb`
  - [ ] Headers de sécurité ajoutés (HSTS, X-Frame-Options, X-Content-Type-Options, X-XSS-Protection, CSP)

**US-1.1.3** — En tant qu'opérateur, je veux que les vulnérabilités XSS soient corrigées, afin de protéger les utilisateurs contre les injections de scripts.
- **Critères d'acceptation :**
  - [ ] `raw()` remplacé par `json_escape()` / `.html_safe` sécurisé dans `search.html.erb`
  - [ ] Audit de tous les helpers utilisant `raw()`
  - [ ] Content Security Policy mise en place

**US-1.1.4** — En tant qu'opérateur, je veux que le remember_token soit renforcé, afin d'empêcher les attaques par bruteforce de session.
- **Critères d'acceptation :**
  - [ ] Token étendu à 64 caractères hexadécimaux (SHA256 complet)
  - [ ] Rotation automatique du token à chaque connexion

**US-1.1.5** — En tant qu'opérateur, je veux un rate limiting sur les endpoints d'authentification, afin de bloquer les attaques par bruteforce.
- **Critères d'acceptation :**
  - [ ] Gem `rack-attack` configurée
  - [ ] Limite de 5 tentatives de connexion par IP / 5 min
  - [ ] Limite de 3 créations de compte par IP / heure
  - [ ] Page 429 personnalisée

---

## PHASE 2 — RENFORCEMENT AUTHENTIFICATION (Sprint 2)

### Epic 2.1 : Système d'authentification robuste

**US-2.1.1** — En tant qu'utilisateur, je veux pouvoir réinitialiser mon mot de passe par email, afin de récupérer l'accès à mon compte.
- **Critères d'acceptation :**
  - [ ] Lien "Mot de passe oublié" sur la page de connexion
  - [ ] Email avec lien de réinitialisation (token expirant en 2h)
  - [ ] Page de nouveau mot de passe
  - [ ] Notification email après changement réussi

**US-2.1.2** — En tant qu'utilisateur, je veux que mon mot de passe respecte des critères de sécurité stricts, afin de protéger mon compte.
- **Critères d'acceptation :**
  - [ ] Minimum 8 caractères
  - [ ] Au moins 1 majuscule, 1 minuscule, 1 chiffre
  - [ ] Vérification contre les mots de passe courants (top 10 000)
  - [ ] Messages d'erreur explicites en cas de non-conformité

**US-2.1.3** — En tant qu'utilisateur, je veux vérifier mon adresse email après inscription, afin de prouver que je possède l'email.
- **Critères d'acceptation :**
  - [ ] Email de vérification envoyé à l'inscription
  - [ ] Token de vérification expirant en 24h
  - [ ] Accès limité tant que l'email n'est pas vérifié
  - [ ] Possibilité de renvoyer l'email de vérification

**US-2.1.4** — En tant qu'utilisateur, je veux activer l'authentification à deux facteurs (2FA/TOTP), afin de sécuriser mon compte.
- **Critères d'acceptation :**
  - [ ] Activation 2FA dans les paramètres du profil
  - [ ] QR code compatible Google Authenticator / Authy
  - [ ] Codes de secours (10 codes à usage unique)
  - [ ] 2FA obligatoire pour les admins

---

## PHASE 3 — REFACTORING TECHNIQUE (Sprint 3)

### Epic 3.1 : Qualité du code et performance

**US-3.1.1** — En tant que développeur, je veux que les N+1 queries soient éliminées, afin d'améliorer les performances de l'application.
- **Critères d'acceptation :**
  - [ ] `search.html.erb` refactorisé avec eager loading (`includes`)
  - [ ] Logique métier déplacée des vues vers les contrôleurs/modèles
  - [ ] Gem `bullet` ajoutée en développement pour détecter les N+1

**US-3.1.2** — En tant que développeur, je veux un nommage cohérent dans toute l'application, afin de faciliter la maintenance.
- **Critères d'acceptation :**
  - [ ] Correction du modèle "Identitie" → "Identity"
  - [ ] Documentation des termes métier (Vol=Flight, Bagage=Luggage, Paquet=Package)
  - [ ] Commentaires en anglais uniformisés

**US-3.1.3** — En tant que développeur, je veux une architecture de contrôleurs propre, afin de respecter le principe de responsabilité unique.
- **Critères d'acceptation :**
  - [ ] Extraction de la logique de recherche dans un service object `FlightSearchService`
  - [ ] Extraction de la logique de booking dans `BookingService`
  - [ ] Concerns partagés pour l'authentification

---

## PHASE 4 — INTERNATIONALISATION (Sprint 4)

### Epic 4.1 : Support multilingue et multi-devises

**US-4.1.1** — En tant qu'utilisateur international, je veux utiliser l'application dans ma langue (FR/EN/ES), afin de comprendre facilement l'interface.
- **Critères d'acceptation :**
  - [ ] Rails I18n configuré avec fichiers `config/locales/{fr,en,es}.yml`
  - [ ] Toutes les chaînes de caractères extraites dans les fichiers de traduction
  - [ ] Sélecteur de langue dans le header
  - [ ] Détection automatique de la langue du navigateur
  - [ ] URLs localisées (`/fr/vols`, `/en/flights`, `/es/vuelos`)

**US-4.1.2** — En tant qu'utilisateur international, je veux voir les prix dans ma devise locale, afin de comparer facilement les offres.
- **Critères d'acceptation :**
  - [ ] Support EUR, USD, GBP, XOF, XAF minimum
  - [ ] Conversion automatique via API de taux de change
  - [ ] Affichage du prix dans la devise de l'utilisateur
  - [ ] Stockage des prix en centimes (integer) pour éviter les erreurs d'arrondi

---

## PHASE 5 — FONCTIONNALITÉS MÉTIER DISRUPTIVES (Sprint 5-7)

### Epic 5.1 : Système d'enchères inversées

**US-5.1.1** — En tant qu'expéditeur, je veux publier une demande d'envoi de colis avec le poids, les dimensions, la ville de départ et d'arrivée, et la date souhaitée, afin que les voyageurs puissent me faire des offres.
- **Critères d'acceptation :**
  - [ ] Formulaire de création de demande (ShippingRequest)
  - [ ] Champs : poids, dimensions, départ, arrivée, date souhaitée, description, photo
  - [ ] Validation des données
  - [ ] Liste publique des demandes actives
  - [ ] Filtres par route, date, poids

**US-5.1.2** — En tant que voyageur, je veux faire une offre sur une demande d'envoi, en proposant mon prix au kilo et ma date de voyage, afin de monétiser mes kilos inutilisés.
- **Critères d'acceptation :**
  - [ ] Bouton "Faire une offre" sur chaque demande
  - [ ] Formulaire d'offre (Bid) : prix au kilo, date de voyage, kilos disponibles, numéro de vol
  - [ ] Notification à l'expéditeur de chaque nouvelle offre
  - [ ] Liste des offres reçues avec comparaison

**US-5.1.3** — En tant qu'expéditeur, je veux accepter une offre, afin de conclure l'accord de transport.
- **Critères d'acceptation :**
  - [ ] Bouton "Accepter l'offre"
  - [ ] Notification au voyageur de l'acceptation
  - [ ] Création automatique du contrat de transport
  - [ ] Les autres offres passent en "refusées"
  - [ ] Email de confirmation aux deux parties

### Epic 5.2 : Publication de kilos disponibles

**US-5.2.1** — En tant que voyageur, je veux publier mes kilos disponibles sur un vol, afin que les expéditeurs puissent les réserver directement.
- **Critères d'acceptation :**
  - [ ] Formulaire de publication (KiloOffer)
  - [ ] Champs : vol, kilos disponibles, prix au kilo, types d'objets acceptés, restrictions
  - [ ] Publication visible sur la recherche
  - [ ] Mise à jour automatique des kilos restants après réservation

**US-5.2.2** — En tant qu'expéditeur, je veux rechercher et réserver des kilos disponibles sur un trajet, afin d'envoyer mon colis.
- **Critères d'acceptation :**
  - [ ] Recherche par trajet (départ/arrivée) et date
  - [ ] Filtres : prix max, poids nécessaire, date
  - [ ] Tri par prix, date, note du voyageur
  - [ ] Réservation directe avec quantité de kilos souhaitée

### Epic 5.3 : Système de paiement sécurisé (Escrow)

**US-5.3.1** — En tant qu'expéditeur, je veux payer de manière sécurisée via un système de séquestre, afin que mon argent ne soit libéré qu'à la livraison confirmée.
- **Critères d'acceptation :**
  - [ ] Intégration Stripe Connect en mode marketplace
  - [ ] Paiement bloqué en escrow à la réservation
  - [ ] Libération du paiement à la confirmation de livraison
  - [ ] Commission plateforme de 10% déduite automatiquement
  - [ ] Remboursement automatique en cas d'annulation
  - [ ] Historique des transactions

**US-5.3.2** — En tant que voyageur, je veux recevoir mon paiement après confirmation de la livraison, afin d'être rémunéré pour le service.
- **Critères d'acceptation :**
  - [ ] Dashboard des paiements en attente/reçus
  - [ ] Virement automatique vers le compte bancaire (Stripe Connect)
  - [ ] Factures générées automatiquement
  - [ ] Litige possible dans les 48h après livraison

### Epic 5.4 : Messagerie temps réel

**US-5.4.1** — En tant qu'utilisateur, je veux communiquer en temps réel avec l'autre partie, afin de coordonner la remise du colis.
- **Critères d'acceptation :**
  - [ ] Messagerie intégrée via Action Cable (WebSocket)
  - [ ] Conversations liées aux réservations
  - [ ] Notifications en temps réel
  - [ ] Historique des messages
  - [ ] Indicateur de message non lu

### Epic 5.5 : Système de confiance et réputation

**US-5.5.1** — En tant qu'utilisateur, je veux vérifier mon identité (KYC), afin d'obtenir un badge "vérifié" et inspirer confiance.
- **Critères d'acceptation :**
  - [ ] Upload de pièce d'identité (recto/verso)
  - [ ] Upload de selfie de vérification
  - [ ] Statut de vérification (en attente, vérifié, refusé)
  - [ ] Badge "Vérifié" sur le profil
  - [ ] Vérification obligatoire pour proposer des kilos

**US-5.5.2** — En tant qu'utilisateur, je veux noter et commenter l'autre partie après une transaction, afin de construire la réputation de la communauté.
- **Critères d'acceptation :**
  - [ ] Système de notation (1-5 étoiles)
  - [ ] Commentaire textuel
  - [ ] Note moyenne affichée sur le profil
  - [ ] Nombre de transactions réussies affiché
  - [ ] Notation possible uniquement après transaction complétée

### Epic 5.6 : Suivi et tracking

**US-5.6.1** — En tant qu'expéditeur, je veux suivre le statut de mon envoi en temps réel, afin de savoir où en est mon colis.
- **Critères d'acceptation :**
  - [ ] Statuts : Créé → Payé → Remis au voyageur → En transit → Livré → Confirmé
  - [ ] Timeline visuelle du statut
  - [ ] Notifications push à chaque changement de statut
  - [ ] Photo de preuve à la remise et à la livraison
  - [ ] Code de confirmation unique pour la remise/réception

---

## PHASE 6 — EXPÉRIENCE MOBILE PWA (Sprint 8)

### Epic 6.1 : Progressive Web App

**US-6.1.1** — En tant qu'utilisateur mobile, je veux installer l'application sur mon écran d'accueil, afin d'y accéder comme une app native.
- **Critères d'acceptation :**
  - [ ] Manifeste PWA (`manifest.json`) configuré
  - [ ] Service Worker pour le cache et le mode hors ligne
  - [ ] Icônes d'application pour toutes les tailles
  - [ ] Splash screen au chargement
  - [ ] Responsive design parfait sur mobile/tablette

**US-6.1.2** — En tant qu'utilisateur mobile, je veux recevoir des notifications push, afin d'être alerté des nouvelles offres et messages.
- **Critères d'acceptation :**
  - [ ] Push notifications via Web Push API
  - [ ] Paramètres de notification personnalisables
  - [ ] Notifications pour : nouvelles offres, messages, changements de statut

---

## PHASE 7 — ANALYTICS ET ADMINISTRATION (Sprint 9)

### Epic 7.1 : Dashboard administrateur amélioré

**US-7.1.1** — En tant qu'administrateur, je veux un tableau de bord avec les métriques clés, afin de piloter la plateforme.
- **Critères d'acceptation :**
  - [ ] Nombre d'utilisateurs actifs (DAU/MAU)
  - [ ] Volume de transactions (nombre et montant)
  - [ ] Taux de conversion (demande → réservation)
  - [ ] Routes les plus populaires
  - [ ] Revenus de la plateforme (commissions)
  - [ ] Alertes en cas d'activité suspecte

**US-7.1.2** — En tant qu'administrateur, je veux gérer les litiges entre utilisateurs, afin de maintenir la confiance sur la plateforme.
- **Critères d'acceptation :**
  - [ ] Interface de gestion des litiges
  - [ ] Historique complet de la transaction
  - [ ] Possibilité de rembourser / débloquer / suspendre
  - [ ] Notification des parties
  - [ ] Audit log de toutes les actions admin

---

## PHASE 8 — TESTS ET CI/CD (Sprint 10)

### Epic 8.1 : Couverture de tests complète

**US-8.1.1** — En tant que développeur, je veux une suite de tests automatisés complète, afin de déployer en confiance.
- **Critères d'acceptation :**
  - [ ] Tests unitaires pour tous les modèles (>90% couverture)
  - [ ] Tests de contrôleurs pour tous les endpoints
  - [ ] Tests d'intégration pour les flux critiques
  - [ ] Tests de sécurité automatisés (Brakeman)
  - [ ] CI/CD pipeline (GitHub Actions)
  - [ ] Tests de performance (N+1 detection)

---

## RÉSUMÉ DES PHASES

| Phase | Sprint | Priorité | Description |
|-------|--------|----------|-------------|
| 1 | S1 | CRITIQUE | Sécurisation des failles critiques |
| 2 | S2 | HAUTE | Renforcement authentification |
| 3 | S3 | HAUTE | Refactoring technique |
| 4 | S4 | MOYENNE | Internationalisation FR/EN/ES |
| 5 | S5-S7 | HAUTE | Fonctionnalités métier disruptives |
| 6 | S8 | MOYENNE | PWA mobile |
| 7 | S9 | BASSE | Analytics et admin |
| 8 | S10 | HAUTE | Tests et CI/CD |

---

## ARCHITECTURE TECHNIQUE CIBLE

```
Rails 5.0.5 (existant) → Sécurisé et étendu
├── Authentication : bcrypt + OmniAuth + 2FA (ROTP gem)
├── Authorization : Pundit (policies)
├── Payments : Stripe Connect (marketplace escrow)
├── Real-time : Action Cable (WebSocket messaging)
├── I18n : Rails I18n + route localization
├── Search : Elasticsearch ou PgSearch
├── Background Jobs : Sidekiq + Redis
├── File Upload : Active Storage (S3)
├── Email : Action Mailer + SendGrid/Mailgun
├── Rate Limiting : Rack::Attack
├── Security Headers : SecureHeaders gem
├── PWA : Service Worker + Web Push
├── Monitoring : Sentry (errors) + New Relic (performance)
└── CI/CD : GitHub Actions
```

## MODÈLE DE DONNÉES ÉTENDU (nouvelles tables)

```
shipping_requests    - Demandes d'envoi (enchères inversées)
bids                 - Offres des voyageurs sur les demandes
kilo_offers          - Kilos disponibles publiés par les voyageurs
transactions         - Paiements et escrow
conversations        - Fils de messagerie
messages             - Messages individuels
reviews              - Avis et notations
identity_verifications - Vérifications KYC
shipment_trackings   - Suivi des envois
notifications        - Notifications utilisateur
```
