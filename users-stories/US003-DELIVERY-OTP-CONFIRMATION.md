# US003 – Confirmation Livraison OTP – Système de preuve de remise par code unique

---

## 🔢 ID
US003 – Delivery – OTPConfirmation

---

## 🧭 Contexte
Sans preuve de livraison, les litiges sont impossibles à trancher. Les transporteurs peuvent prétendre avoir livré sans l'avoir fait, et les expéditeurs peuvent nier avoir reçu le colis. Un système OTP (One-Time Password) permet une validation irréfutable de la remise.

---

## 🏛 Domaine
Delivery / Operations

---

## 👤 En tant que
Transporteur / Destinataire / Système

---

## 🎯 Je veux
Confirmer la livraison via un code unique partagé uniquement au moment de la remise

---

## 💼 Afin de
Prouver la livraison effective, débloquer le paiement et éviter les litiges

---

# ✔️ Critères d'acceptation

## 🎬 Scénarios Gherkin
### Scénario 1 : Génération du code OTP
- **Given** Un transporteur arrive au point de livraison
- **When** Il clique sur "Commencer livraison"
- **Then** Un code 6 chiffres est envoyé au destinataire par SMS/Email

### Scénario 2 : Validation du code correct
- **Given** Le destinataire communique le code "123456" au transporteur
- **When** Le transporteur saisit ce code dans l'app
- **Then** La livraison est confirmée et les fonds sont libérés

### Scénario 3 : Échec avec mauvais code
- **Given** Un transporteur tente de saisir un faux code
- **When** Il entre "999999" (incorrect)
- **Then** Erreur affichée, 2 essais restants, livraison non confirmée

## 📐 Règles fonctionnelles
- [ ] Code OTP : 6 chiffres, validité 30 minutes
- [ ] Maximum 3 tentatives avant blocage
- [ ] Photo obligatoire du colis au moment de la saisie OTP
- [ ] Géolocalisation enregistrée à la validation
- [ ] Notification immédiate à l'expéditeur après confirmation

## 🛠 Critères techniques
- [ ] SMS via Twilio ou Vonage
- [ ] Fallback email si SMS échoue
- [ ] Codes stockés hashés (bcrypt)
- [ ] Rate limiting sur génération (1/minute)

## 🔐 Critères de sécurité
- [ ] Codes non prédictibles (SecureRandom)
- [ ] Expiration automatique après 30 min
- [ ] Blocage IP après 10 échecs/jour
- [ ] Audit log complet du processus

## ⚡ Critères de performance
- [ ] Envoi SMS < 3 secondes
- [ ] Validation code < 500ms
- [ ] Support 1000 livraisons simultanées

## 📘 Documentation
- [ ] Guide livraison pour transporteurs
- [ ] FAQ destinataires sur OTP

---

# 🧮 Priorité
P0 (Critique - Trust & Safety)

---

# 🔢 Complexité (Points Fibonacci)
5

---

# 🔗 Dépendances
- Service SMS (Twilio/Vonage)
- Gem `twilio-ruby` ou équivalent
- Service géolocalisation mobile
- Upload photos vers S3/Cloudinary

---

# 🧪 Tests

### Unitaires
- OTP generation (unicité, format)
- Validation logic avec expiration
- SMS service avec mocks

### Intégration
- Workflow complet génération → validation
- Fallback email si SMS fail
- Géolocalisation + photo

### E2E
- Parcours livraison complet mobile
- Simulation timeout OTP

### Cas limites
- Réseau mobile indisponible
- Destinataire sans téléphone
- Multiple codes simultanés

### Cas d'erreur
- SMS provider down
- Code expiré
- GPS désactivé

### Sécurité
- Brute force attempts
- Code replay après expiration
- Usurpation identité destinataire

### Performance
- 500 validations/seconde
- Bulk SMS sending

---

# 🧭 Chemin critique (Critical Path)

### 🔥 Tâches critiques
1. Intégration Twilio/Vonage
2. Model DeliveryConfirmation avec OTP
3. Service OTPService (generate/validate)
4. UI mobile pour saisie code
5. Webhook liberation paiement

### 📌 Risques associés au chemin critique
- Risque 1 : Coût SMS élevé (mitigation : négocier tarifs volume)
- Risque 2 : Destinataire injoignable (mitigation : email backup + contact expéditeur)

---

# 🔄 PDCA – Cycle d'amélioration continue intégré

### 🟦 **P – Plan (Planifier)**
- Objectif : 100% livraisons avec preuve
- Hypothèse : SMS reçus dans 95% des cas
- KPI : Litiges livraison < 1%

### 🟩 **D – Do (Réaliser)**
- Sprint 1 : Backend OTP + SMS
- Sprint 2 : UI mobile validation
- Sprint 3 : Dashboard tracking

### 🟧 **C – Check (Vérifier)**
- Taux de SMS delivered
- Temps moyen validation
- Taux d'échec OTP

### 🟥 **A – Act (Ajuster)**
- WhatsApp comme canal alternatif
- QR code si pas de réseau
- Signature électronique backup

---

# 🏗 État
❌ Non commencé

---

# 🛠 Notes d'implémentation
- Architecture : Service Object OTPService
- Background job pour envoi SMS (éviter blocking)
- Redis pour stockage temporaire OTP
- Géofencing pour validation proximité

---

# 📚 Références
- Service : `app/services/otp_service.rb`
- Model : `app/models/delivery_confirmation.rb`
- Controller : `app/controllers/api/deliveries_controller.rb`
- Tests : `spec/services/otp_service_spec.rb`
- Twilio Docs : https://www.twilio.com/docs/verify

---

# 📈 Métriques de succès (KPI)
- Taux confirmation livraison > 98%
- Temps moyen validation < 2 minutes
- Litiges post-OTP < 0.5%
- SMS delivery rate > 95%
- Coût par confirmation < 0.15€

---

# 🏁 Définition de "Done"
- [ ] OTP generation et validation OK
- [ ] SMS + email fallback actifs
- [ ] Photo + GPS obligatoires
- [ ] Tests coverage > 90%
- [ ] Monitoring Twilio webhook
- [ ] Documentation livreurs
- [ ] Analytics dashboard

---

# 🕰 Historique
- 2024-01-29 : Création user story
- À venir : Implémentation

---

# 📓 Notes de Sprint
- Prévoir numéros tests Twilio
- UX critique : clarté instructions
- Support multilingue SMS