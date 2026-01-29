# US004 – Vérification KYC Stripe Identity – Validation d'identité automatisée

---

## 🔢 ID
US004 – Security – KYCVerification

---

## 🧭 Contexte
La plateforme permet actuellement à n'importe qui de créer un compte sans vérification d'identité. Cela expose ShareMyBag à des risques de fraude, blanchiment d'argent et usurpation d'identité. Une vérification KYC (Know Your Customer) est légalement requise pour les transactions financières.

---

## 🏛 Domaine
Security / Compliance

---

## 👤 En tant que
Utilisateur / Admin / Système

---

## 🎯 Je veux
Vérifier l'identité réelle des utilisateurs via documents officiels

---

## 💼 Afin de
Respecter les réglementations anti-blanchiment (AML), prévenir la fraude et créer un environnement de confiance

---

# ✔️ Critères d'acceptation

## 🎬 Scénarios Gherkin
### Scénario 1 : Vérification réussie
- **Given** Un utilisateur upload son passeport + selfie
- **When** Stripe Identity analyse les documents
- **Then** Le compte passe en statut "verified" avec badge visible

### Scénario 2 : Rejet pour document invalide
- **Given** Un utilisateur soumet une carte périmée
- **When** L'API détecte la date d'expiration
- **Then** Statut "rejected" avec demande de nouveau document

### Scénario 3 : Limitation avant vérification
- **Given** Un utilisateur non vérifié tente une transaction > 100€
- **When** Il essaie d'accepter une offre
- **Then** Redirection vers processus KYC obligatoire

## 📐 Règles fonctionnelles
- [ ] Documents acceptés : Passeport, CNI, Permis conduire
- [ ] Selfie avec liveness detection obligatoire
- [ ] Vérification requise pour : transactions > 100€, plus de 3 transactions
- [ ] Validité vérification : 2 ans puis re-vérification
- [ ] Données conservées maximum 5 ans (RGPD)

## 🛠 Critères techniques
- [ ] Stripe Identity API pour vérification
- [ ] Fallback Jumio si Stripe indisponible
- [ ] Webhooks pour résultats async
- [ ] Chiffrement documents at-rest

## 🔐 Critères de sécurité
- [ ] Zero stockage documents côté app
- [ ] Tokenization des résultats vérification
- [ ] Audit trail complet (qui, quand, quoi)
- [ ] Blocage après 3 échecs vérification

## ⚡ Critères de performance
- [ ] Upload documents < 10 secondes
- [ ] Résultat vérification < 2 minutes
- [ ] Support files jusqu'à 10MB

## 📘 Documentation
- [ ] Guide vérification avec exemples visuels
- [ ] FAQ documents acceptés par pays
- [ ] Politique de confidentialité mise à jour

---

# 🧮 Priorité
P0 (Légal - Obligatoire)

---

# 🔢 Complexité (Points Fibonacci)
8

---

# 🔗 Dépendances
- Stripe Identity (activation requise)
- Gem `stripe` avec version compatible
- Service stockage sécurisé (via Stripe)
- Mise à jour CGU/RGPD

---

# 🧪 Tests

### Unitaires
- IdentityVerification model states
- KYCService avec mocks Stripe
- Eligibility rules engine

### Intégration
- Upload documents → webhook → status update
- Multi-documents workflow
- Retry après échec

### E2E
- Parcours vérification complet
- Blocages transactions non-vérifiés

### Cas limites
- Document illisible/flou
- Nom différent (mariage, etc.)
- Mineur tentant vérification

### Cas d'erreur
- API Stripe down
- Upload timeout
- Document corrompu

### Sécurité
- Upload fichier malveillant
- Tentative avec faux documents
- GDPR data request/deletion

### Performance
- 100 vérifications simultanées
- Large files (10MB photos)

---

# 🧭 Chemin critique (Critical Path)

### 🔥 Tâches critiques
1. Activation Stripe Identity sur compte
2. Migration model IdentityVerification
3. Service KYCVerificationService
4. UI workflow vérification
5. Restrictions transactions non-vérifiés

### 📌 Risques associés au chemin critique
- Risque 1 : Rejet Stripe pour activité high-risk (mitigation : clarifier business model)
- Risque 2 : Taux rejet élevé mauvaise qualité photos (mitigation : guide visuel clair)

---

# 🔄 PDCA – Cycle d'amélioration continue intégré

### 🟦 **P – Plan (Planifier)**
- Objectif : 90% utilisateurs actifs vérifiés
- Hypothèse : 80% réussite première tentative
- KPI : Fraude identité < 0.01%

### 🟩 **D – Do (Réaliser)**
- Phase 1 : Vérification nouveaux users
- Phase 2 : Campaign existing users
- Phase 3 : Vérification continue (AML)

### 🟧 **C – Check (Vérifier)**
- Taux conversion vérification
- Raisons principales rejets
- Impact sur acquisition users

### 🟥 **A – Act (Ajuster)**
- Améliorer UX upload mobile
- Support documents additionnels
- Vérification progressive (tiers)

---

# 🏗 État
❌ Non commencé

---

# 🛠 Notes d'implémentation
- State machine : pending → processing → verified/rejected
- Async processing via webhooks
- Graceful degradation si API down
- Cache verification status (1h)

---

# 📚 Références
- Service : `app/services/kyc_verification_service.rb`
- Model : `app/models/identity_verification.rb`
- Controller : `app/controllers/identity_verifications_controller.rb`
- Stripe Docs : https://stripe.com/docs/identity
- Tests : `spec/services/kyc_verification_service_spec.rb`

---

# 📈 Métriques de succès (KPI)
- Taux vérification complétée > 85%
- Temps moyen vérification < 3 min
- False positive rate < 2%
- Fraude post-KYC < 0.01%
- Compliance score 100%

---

# 🏁 Définition de "Done"
- [ ] Stripe Identity intégré
- [ ] Workflow UX mobile-first
- [ ] Restrictions appliquées non-vérifiés
- [ ] Tests coverage > 95%
- [ ] RGPD compliance validé
- [ ] Dashboard admin vérifications
- [ ] Documentation utilisateurs

---

# 🕰 Historique
- 2024-01-29 : Création user story
- À venir : Implémentation

---

# 📓 Notes de Sprint
- Priorité absolue compliance
- Prévoir budget vérifications test
- UX critique pour conversion