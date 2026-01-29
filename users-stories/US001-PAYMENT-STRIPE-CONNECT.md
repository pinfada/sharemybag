# US001 – Intégration Stripe Connect – Système de paiement sécurisé avec escrow

---

## 🔢 ID
US001 – Payment – StripeConnect

---

## 🧭 Contexte
ShareMyBag ne possède actuellement aucun système de paiement, rendant impossible toute transaction réelle. Sans mécanisme d'escrow, les expéditeurs risquent de payer sans recevoir leur colis et les transporteurs de livrer sans être payés. Cette lacune critique bloque toute opération commerciale.

---

## 🏛 Domaine
Payment

---

## 👤 En tant que
Expéditeur / Transporteur / Système

---

## 🎯 Je veux
Pouvoir effectuer et recevoir des paiements sécurisés avec mise en séquestre automatique des fonds

---

## 💼 Afin de
Garantir la sécurité financière de toutes les parties et permettre à la plateforme de percevoir sa commission (15%)

---

# ✔️ Critères d'acceptation

## 🎬 Scénarios Gherkin
### Scénario 1 : Paiement lors de l'acceptation d'une offre
- **Given** Un expéditeur a accepté une offre de transport à 50€
- **When** Il clique sur "Accepter et payer"
- **Then** Il est redirigé vers Stripe Checkout et les fonds sont prélevés avec hold

### Scénario 2 : Libération des fonds après livraison
- **Given** Un transporteur a livré le colis avec code OTP confirmé
- **When** Le statut passe à "delivered"
- **Then** Les fonds (42.50€ après commission) sont transférés sur son compte Stripe Connect

### Scénario 3 : Remboursement en cas de litige
- **Given** Un litige est ouvert et validé par l'admin
- **When** L'admin déclenche le remboursement
- **Then** Les fonds en escrow retournent à l'expéditeur

## 📐 Règles fonctionnelles
- [ ] Commission plateforme fixée à 15% prélevée automatiquement
- [ ] Délai maximum d'escrow : 30 jours après date de livraison prévue
- [ ] Multi-devises supportées (EUR, USD, GBP, XOF, XAF) avec conversion
- [ ] Minimum de transaction : 10€ ou équivalent

## 🛠 Critères techniques
- [ ] Intégration Stripe Connect Express pour onboarding simplifié
- [ ] Webhooks Stripe pour synchronisation états (payment.intent.succeeded, transfer.created)
- [ ] Idempotence keys sur toutes les opérations financières
- [ ] Retry logic avec exponential backoff

## 🔐 Critères de sécurité
- [ ] Aucun stockage de données bancaires côté application
- [ ] PCI DSS compliance via Stripe
- [ ] Audit log de toutes les transactions
- [ ] 3D Secure activé pour paiements > 30€

## ⚡ Critères de performance
- [ ] Temps de checkout < 3 secondes
- [ ] Webhook processing < 500ms
- [ ] Support de 100 transactions/minute

## 📘 Documentation
- [ ] Guide d'intégration transporteur
- [ ] FAQ paiements et remboursements

---

# 🧮 Priorité
P0 (Bloquant - Critique)

---

# 🔢 Complexité (Points Fibonacci)
13

---

# 🔗 Dépendances
- Gem `stripe` (~> 9.0)
- Gem `money-rails` pour gestion devises
- API Fixer.io pour taux de change
- Compte Stripe avec Connect activé
- Certificat SSL (HTTPS obligatoire)

---

# 🧪 Tests

### Unitaires
- Transaction model avec états (pending, held, released, refunded)
- StripeService avec mocks des API calls
- Commission calculation service

### Intégration
- Workflow complet paiement → escrow → libération
- Gestion des webhooks Stripe

### E2E
- Parcours checkout avec carte test
- Simulation livraison et libération fonds

### Cas limites
- Paiement échoué après 3 tentatives
- Webhook timeout et retry
- Devise non supportée

### Cas d'erreur
- Carte refusée / insuffisante
- Compte Stripe suspendu
- Network failure pendant transaction

### Sécurité
- Tentative de manipulation du montant
- Webhook forgé (signature invalide)

### Performance
- 500 paiements simultanés
- Webhook burst (100 req/sec)

---

# 🧭 Chemin critique (Critical Path)

### 🔥 Tâches critiques
1. Configuration compte Stripe + activation Connect
2. Modèles Transaction et StripeAccount
3. Service StripePaymentService avec hold/release
4. Controllers webhooks avec vérification signature
5. Frontend checkout avec Stripe.js

### 📌 Risques associés au chemin critique
- Risque 1 : Délai activation Stripe Connect (mitigation : compte test d'abord)
- Risque 2 : Complexité multi-devises (mitigation : commencer EUR uniquement)

---

# 🔄 PDCA – Cycle d'amélioration continue intégré

### 🟦 **P – Plan (Planifier)**
- Objectif : 0% de transactions échouées pour raisons techniques
- Hypothèse : 15% commission acceptable pour utilisateurs
- KPI : Taux de conversion checkout > 80%

### 🟩 **D – Do (Réaliser)**
- Sprint 1 : Backend Stripe + modèles
- Sprint 2 : Frontend checkout + webhooks
- Sprint 3 : Dashboard admin + reporting

### 🟧 **C – Check (Vérifier)**
- Monitoring taux échec paiement
- Analyse abandons checkout
- Feedback utilisateurs sur UX paiement

### 🟥 **A – Act (Ajuster)**
- Optimisation checkout (moins d'étapes)
- A/B test sur montant commission
- Support wallets (Apple Pay, Google Pay)

---

# 🏗 État
❌ Non commencé

---

# 🛠 Notes d'implémentation
- Architecture : Service Object pattern pour StripePaymentService
- État machine pour Transaction (AASM gem)
- Jobs async pour webhooks processing (Sidekiq)
- Cache des taux de change (1h TTL)

---

# 📚 Références
- Code : `app/services/stripe_payment_service.rb`
- Model : `app/models/transaction.rb`
- Controller : `app/controllers/webhooks/stripe_controller.rb`
- Tests : `spec/services/stripe_payment_service_spec.rb`
- Docs Stripe : https://stripe.com/docs/connect

---

# 📈 Métriques de succès (KPI)
- Taux de conversion checkout > 80%
- Temps moyen checkout < 90 secondes
- Taux d'échec technique < 0.1%
- Commission nette après frais Stripe > 12%
- NPS paiement > 8/10

---

# 🏁 Définition de "Done"
- [ ] Paiement fonctionnel en test et production
- [ ] Escrow avec hold/release validé
- [ ] Webhooks resilients et idempotents
- [ ] Tests coverage > 90%
- [ ] Documentation marchande complète
- [ ] Monitoring Datadog/NewRelic actif
- [ ] Conformité PCI DSS validée

---

# 🕰 Historique
- 2024-01-29 : Création user story
- À venir : Implémentation

---

# 📓 Notes de Sprint
- Point critique pour lancement MVP
- Prévoir formation équipe support
- Sandbox Stripe pour tous les devs