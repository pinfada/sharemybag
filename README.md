# ShareMyBag Exchange — B2B Airline Baggage Allowance Exchange

[![Try with railsbox](https://pinfada.github.io/tchopmygrinds/badge.svg)](https://pinfada.github.io/sharemybag/)

**ShareMyBag Exchange** is a white-label **B2B flight-level baggage allowance exchange** enabling airlines to monetize unused hold baggage capacity ("Ghost Allowance") on every commercial departure:

1. **Zero Physical Parcel Handover** — Between **T-48h and T-4h**, ticketed passengers on the **same commercial flight** trade **digital PNR weight allowance** on a live Bid/Ask order book. Every passenger packs and checks only their own suitcase — avoiding physical parcel handover between passengers. Carrier approval and operational validation are required.
2. **Atomic Price-Time Priority Matching Engine** — `OrderBookMatchingService` matches crossing limit orders inside a locked PostgreSQL transaction with fractional fills, maker-price execution, overdraft protection, anti-wash-trading, IATA 32 kg single-bag health notice, and certified aircraft payload limits (`A350-900`, `B777-300ER`, `A330-200`, `B737-800`, `A320neo`).
3. **Carrier-Agnostic DCS / PSS Integration Layer (`/integrations`)** — Pluggable adapters (`IataNdcAdapter` for Amadeus Altéa/Sabre ONE Order, `NavitaireRestAdapter`, `WebhookRestAdapter` with HMAC-SHA256, `SandboxAdapter`) orchestrated by `AirlineDcs::SettlementOrchestrator` with idempotent IATA EMD-A/EMD-S issuance, tracked compensation (buyer EMD void and seller allowance restoration), SSRF/TLS validation, and signed inbound webhooks (`POST /api/v1/dcs/webhooks/:airline_code`).
4. **CFO-Ready Airline ROI & Fleet Simulator (`/airline-roi`)** — Auditable unit economics including 25% commission, 100% retained flight voucher treasury, marginal Jet-A1 fuel burn deduction (`3.5%/h × flight hours × €1.10/kg`), counter cannibalization stress-test, belly cargo yield comparison, and check-in agent hours saved.

Built with **Ruby on Rails 7.0** and **PostgreSQL 16**, accessible to **RGAA 4.1 / WCAG 2.1 Level AA**, hardened to **OWASP** standards (strict CSP, zero inline scripts/styles, `Rack::Attack`), and zero ExecJS dependency (fully compatible with `railsbox`).

## Live Playable Demo

**→ [pinfada.github.io/sharemybag](https://pinfada.github.io/sharemybag/)**

1-click demo personas pre-booked on **AF718 (CDG → DKR)**:

| Persona | Email | Password |
| --- | --- | --- |
| Light Traveler (Seller — ASK) | `marie@example.com` | `Marie123!` |
| Heavy Traveler (Buyer — BID) | `pierre@example.com` | `Pierre123!` |
| Airline Revenue VP | `vp@airfrance-demo.com` | `Airline123!` |

## Local Development & Tests

```bash
bundle install
bin/rails db:create db:schema:load db:seed
bin/rails zeitwerk:check
bin/rails test
bin/rails server
```


## Carrier settlement

Matched kilos are reserved locally while settlement is pending. The displayed
allowance, voucher balance, and passenger confirmation update after the carrier
acknowledges settlement. A definitive rejection releases the reserved quantities
once all required reversals are acknowledged. An unknown live outcome keeps the
reservation in place.

Run `bin/rails dcs:retry_settlements FLIGHT_ID=123` to retry an affected flight.
Without `FLIGHT_ID`, the task scans all unresolved trades. Settlement advances in
trade order per flight. The carrier must honor the same idempotency key on retry
and use `outcome: "REJECTED"` only for a definitive rejection with no side effect.
The generic webhook gateway restores the seller's allowance through
`POST allowances/restore`. Validate the endpoints, acknowledgements and replay
behavior with the carrier before enabling a live connector. Allowance accounting
tracks booked entitlements. Actual loaded baggage can increase when a previously
unused entitlement is used by the buyer.
