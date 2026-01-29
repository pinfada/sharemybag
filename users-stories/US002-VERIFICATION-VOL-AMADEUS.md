# US002 – Vérification Vol Amadeus – Validation automatique des billets d'avion

---

## 🔢 ID
US002 – Security – FlightVerification

---

## 🧭 Contexte
Actuellement, aucune vérification n'est effectuée pour s'assurer que le transporteur prend réellement l'avion annoncé. Cela expose la plateforme à des fraudes où des personnes pourraient créer de fausses offres sans jamais voyager. La validation automatique des vols est cruciale pour la confiance.

---

## 🏛 Domaine
Security / Verification

---

## 👤 En tant que
Transporteur / Expéditeur / Système

---

## 🎯 Je veux
Valider automatiquement l'existence et les détails d'un vol via son numéro

---

## 💼 Afin de
Garantir que seuls les vrais voyageurs peuvent proposer du transport et rassurer les expéditeurs

---

# ✔️ Critères d'acceptation

## 🎬 Scénarios Gherkin
### Scénario 1 : Validation d'un vol existant
- **Given** Un transporteur entre le vol "AF1234" pour le 15/03/2024
- **When** Le système interroge l'API Amadeus
- **Then** Le vol est confirmé avec horaires Paris CDG 10h30 → New York JFK 13h45

### Scénario 2 : Rejet d'un vol inexistant
- **Given** Un transporteur entre un faux numéro "XX9999"
- **When** Le système vérifie via API
- **Then** L'offre est rejetée avec message "Vol introuvable"

### Scénario 3 : Vérification OCR du billet
- **Given** Un transporteur upload son billet PDF
- **When** Le système extrait les données via OCR
- **Then** Le nom, numéro de vol et date correspondent au compte utilisateur

## 📐 Règles fonctionnelles
- [ ] Vol doit être dans les 48h-6 mois à venir
- [ ] Nom sur billet doit matcher à 90% le nom du compte
- [ ] Statut vol doit être "Scheduled" (pas annulé)
- [ ] Aéroports départ/arrivée doivent matcher la ShippingRequest

## 🛠 Critères techniques
- [ ] Intégration API Amadeus Self-Service
- [ ] OCR avec Textract AWS ou Google Vision
- [ ] Cache des vols vérifiés (24h)
- [ ] Fallback sur FlightRadar24 si Amadeus down

## 🔐 Critères de sécurité
- [ ] API keys Amadeus en variables d'environnement
- [ ] Rate limiting : 10 vérifications/user/jour
- [ ] Logs des tentatives de fraude
- [ ] Blocage après 3 faux vols

## ⚡ Critères de performance
- [ ] Réponse API < 2 secondes
- [ ] OCR processing < 5 secondes
- [ ] Cache hit ratio > 60%

## 📘 Documentation
- [ ] Guide upload billet pour transporteurs
- [ ] FAQ erreurs courantes validation

---

# 🧮 Priorité
P0 (Critique pour confiance)

---

# 🔢 Complexité (Points Fibonacci)
8

---

# 🔗 Dépendances
- API Amadeus for Developers (Self-Service tier)
- AWS Textract ou Google Cloud Vision
- Gem `amadeus` ou HTTP client
- Redis pour cache

---

# 🧪 Tests

### Unitaires
- FlightVerificationService avec vols mockés
- OCR parser avec PDFs exemples
- Name matching algorithm

### Intégration
- Appel réel API Amadeus (test env)
- Upload et parsing billet complet

### E2E
- Parcours création offre avec validation vol

### Cas limites
- Vol codeshare (plusieurs numéros)
- Nom avec caractères spéciaux/accents
- Vol avec escale

### Cas d'erreur
- API Amadeus timeout
- PDF corrompu/illisible
- Vol annulé dernière minute

### Sécurité
- Upload fichier malveillant
- Tentative bypass avec vol périmé

### Performance
- 100 vérifications simultanées
- PDF de 10MB

---

# 🧭 Chemin critique (Critical Path)

### 🔥 Tâches critiques
1. Compte Amadeus API + credentials
2. Service FlightVerificationService
3. Intégration OCR pour billets PDF
4. UI upload billet dans KiloOffer
5. Background job pour vérification async

### 📌 Risques associés au chemin critique
- Risque 1 : Coût API Amadeus élevé (mitigation : cache agressif)
- Risque 2 : OCR imprécis sur billets low-cost (mitigation : validation manuelle fallback)

---

# 🔄 PDCA – Cycle d'amélioration continue intégré

### 🟦 **P – Plan (Planifier)**
- Objectif : 95% des vols vérifiés automatiquement
- Hypothèse : OCR suffisant pour 80% des billets
- KPI : Taux de fraude < 0.1%

### 🟩 **D – Do (Réaliser)**
- Phase 1 : API Amadeus uniquement
- Phase 2 : Ajout OCR billets
- Phase 3 : Machine learning anti-fraude

### 🟧 **C – Check (Vérifier)**
- Taux de faux positifs (vrais vols rejetés)
- Temps moyen de vérification
- Coût mensuel API

### 🟥 **A – Act (Ajuster)**
- Améliorer algorithme matching noms
- Ajouter providers backup (Duffel, Sabre)
- Self-learning sur patterns fraude

---

# 🏗 État
❌ Non commencé

---

# 🛠 Notes d'implémentation
- Pattern : Service Object + Adapter pour multi-providers
- Async processing via ActiveJob
- Circuit breaker pour API externes
- Stockage billets chiffrés S3

---

# 📚 Références
- Service : `app/services/flight_verification_service.rb`
- Job : `app/jobs/verify_flight_job.rb`
- API Docs : https://developers.amadeus.com
- Tests : `spec/services/flight_verification_service_spec.rb`

---

# 📈 Métriques de succès (KPI)
- Vérification automatique > 95%
- Faux positifs < 2%
- Détection fraude > 99%
- Coût API < 0.10€/vérification
- User satisfaction score > 4.5/5

---

# 🏁 Définition de "Done"
- [ ] API Amadeus intégrée et testée
- [ ] OCR fonctionnel sur 5 formats billets
- [ ] Cache Redis optimisé
- [ ] Tests coverage > 85%
- [ ] Dashboard admin fraudes
- [ ] Alerting sur patterns suspects
- [ ] Documentation transporteurs

---

# 🕰 Historique
- 2024-01-29 : Création user story
- À venir : Implémentation

---

# 📓 Notes de Sprint
- Commencer par airlines majeures
- Prévoir budget API tests
- Former support sur cas edge