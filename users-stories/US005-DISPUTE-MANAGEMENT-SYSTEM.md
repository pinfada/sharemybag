# US005 – Système de Gestion des Litiges – Arbitrage et résolution des conflits

---

## 🔢 ID
US005 – Operations – DisputeManagement

---

## 🧭 Contexte
Sans système de gestion des litiges, les conflits entre utilisateurs restent non résolus, créant frustration et perte de confiance. Les cas de colis endommagés, perdus ou non livrés nécessitent un processus d'arbitrage structuré avec preuves et décisions transparentes.

---

## 🏛 Domaine
Operations / Support

---

## 👤 En tant que
Expéditeur / Transporteur / Admin / Médiateur

---

## 🎯 Je veux
Pouvoir ouvrir, documenter et résoudre un litige de manière équitable

---

## 💼 Afin de
Protéger tous les utilisateurs, maintenir la confiance et respecter les obligations légales de médiation

---

# ✔️ Critères d'acceptation

## 🎬 Scénarios Gherkin
### Scénario 1 : Ouverture d'un litige
- **Given** Une livraison marquée complète mais colis endommagé
- **When** L'expéditeur ouvre un litige dans les 48h avec photos
- **Then** Le litige est créé, transporteur notifié, fonds bloqués

### Scénario 2 : Escalade automatique
- **Given** Un litige ouvert depuis 72h sans réponse transporteur
- **When** Le délai expire
- **Then** Escalade automatique vers équipe médiation ShareMyBag

### Scénario 3 : Résolution avec remboursement partiel
- **Given** Le médiateur constate dommage partiel après analyse preuves
- **When** Il décide d'un remboursement 50%
- **Then** 50% retournés à l'expéditeur, 50% au transporteur, litige clos

## 📐 Règles fonctionnelles
- [ ] Délai ouverture litige : 48h après livraison
- [ ] Types : Non-livré, Endommagé, Contenu différent, Retard excessif
- [ ] Preuves obligatoires : Photos avant/après, messages, tracking
- [ ] Escalade auto après 72h sans réponse
- [ ] Décisions possibles : Remboursement total/partiel, Rejet, Compensation

## 🛠 Critères techniques
- [ ] Upload multiple photos/vidéos (max 50MB)
- [ ] Timeline interactive des événements
- [ ] Système de messagerie interne au litige
- [ ] Export PDF du dossier complet

## 🔐 Critères de sécurité
- [ ] Preuves immuables (hash blockchain/IPFS)
- [ ] Audit trail des décisions
- [ ] Anonymisation après résolution (RGPD)
- [ ] Accès restreint médiateurs certifiés

## ⚡ Critères de performance
- [ ] Chargement dossier < 2 secondes
- [ ] Support 1000 litiges actifs
- [ ] Recherche fulltext instantanée

## 📘 Documentation
- [ ] Guide ouverture litige avec exemples
- [ ] Matrice décisions pour médiateurs
- [ ] FAQ sur processus et délais

---

# 🧮 Priorité
P0 (Critique - Trust & Legal)

---

# 🔢 Complexité (Points Fibonacci)
13

---

# 🔗 Dépendances
- Service stockage media (S3/Cloudinary)
- Système notification temps réel
- Integration paiement pour remboursements
- Formation équipe médiation

---

# 🧪 Tests

### Unitaires
- Dispute state machine (opened → investigating → resolved)
- Eligibility rules (délais, types)
- Calculation remboursement

### Intégration
- Workflow complet avec escalade
- Notifications tous acteurs
- Remboursement automatique

### E2E
- Parcours ouverture → résolution
- Dashboard médiateur

### Cas limites
- Litige sur litige
- Multiple litiges même transaction
- Preuves contradictoires

### Cas d'erreur
- Upload preuves échoué
- Remboursement impossible (compte fermé)
- Transporteur introuvable

### Sécurité
- Tentative manipulation preuves
- Accès unauthorized au litige
- Flood litiges abusifs

### Performance
- 100 litiges ouverts simultanément
- Dashboard avec 10K litiges

---

# 🧭 Chemin critique (Critical Path)

### 🔥 Tâches critiques
1. Model Dispute avec state machine
2. Service DisputeResolutionService
3. UI formulaire ouverture avec upload
4. Dashboard admin médiation
5. Integration remboursement Stripe

### 📌 Risques associés au chemin critique
- Risque 1 : Complexité légale par juridiction (mitigation : CGU arbitrage uniforme)
- Risque 2 : Coût médiation humaine (mitigation : AI pré-analyse + templates décisions)

---

# 🔄 PDCA – Cycle d'amélioration continue intégré

### 🟦 **P – Plan (Planifier)**
- Objectif : Résolution < 5 jours ouvrés
- Hypothèse : 70% résolus sans escalade
- KPI : Satisfaction résolution > 7/10

### 🟩 **D – Do (Réaliser)**
- Sprint 1 : Core dispute model + UI
- Sprint 2 : Dashboard médiation
- Sprint 3 : Automatisation décisions simples

### 🟧 **C – Check (Vérifier)**
- Temps moyen résolution
- Taux escalade manuel
- Patterns litiges récurrents

### 🟥 **A – Act (Ajuster)**
- Templates décisions fréquentes
- ML pour pré-catégorisation
- Médiation vidéo pour cas complexes

---

# 🏗 État
❌ Non commencé

---

# 🛠 Notes d'implémentation
- AASM gem pour state machine
- ActionCable pour updates real-time
- Sidekiq pour jobs escalade
- ElasticSearch pour recherche

---

# 📚 Références
- Model : `app/models/dispute.rb`
- Service : `app/services/dispute_resolution_service.rb`
- Controller : `app/controllers/disputes_controller.rb`
- Admin : `app/controllers/admin/disputes_controller.rb`
- Tests : `spec/models/dispute_spec.rb`

---

# 📈 Métriques de succès (KPI)
- Temps résolution médian < 72h
- Taux satisfaction > 75%
- Litiges / 1000 transactions < 5
- Coût médiation < 2% GMV
- Repeat disputes < 1%

---

# 🏁 Définition de "Done"
- [ ] Workflow litige complet fonctionnel
- [ ] Dashboard médiation avec filtres
- [ ] Remboursements automatisés
- [ ] Tests coverage > 90%
- [ ] Documentation processus
- [ ] Formation équipe support
- [ ] Templates décisions

---

# 🕰 Historique
- 2024-01-29 : Création user story
- À venir : Implémentation

---

# 📓 Notes de Sprint
- Benchmark : Airbnb Resolution Center
- Prévoir avocat pour validation CGU
- UX mobile prioritaire