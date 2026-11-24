# ShareMyBag Exchange — B2B Airline Baggage Allowance Exchange (`lab/b2b-airline-exchange`)

> **Branch Note:** `master` keeps the standalone P2P parcel reverse-auction demo. This `lab/b2b-airline-exchange` branch implements the **B2B white-label Airline Baggage Allowance Exchange** where airlines monetize unused hold baggage capacity on every commercial departure.

## Core Feature (One Focused Problem, Solved End-to-End)

Between **T-48h and T-4h** before departure, ticketed passengers on the **same commercial flight** trade **digital baggage weight allowance** on a live **Bid / Ask order book**:

1. **Zero Physical Parcel Handover** — Passengers pack and check only their own suitcase. Only digital weight entitlements move 1:1 between two PNRs on the same flight, eliminating airport security (DGAC/TSA/ICAO Annex 17), customs, and airline terms blockers.
2. **Price-Time Priority Matching Engine** — `OrderBookMatchingService` matches crossing limit orders atomically inside a locked PostgreSQL transaction with fractional fills, maker-price execution, overdraft protection, anti-wash-trading, and strict certified aircraft payload limits (`A350-900`, `B777-300ER`, `A330-200`, `B737-800`, `A320neo`).
3. **IATA 32 kg Single-Bag Health Limit & H-4h Weight & Balance Cutoff** — PNR allowance can scale up to 46 kg (with mandatory 2-bag split notice above 32 kg) and trading freezes 4 hours before departure.
4. **Auditable Airline ROI & Annual Fleet Simulator** — `AirlineEconomicsService` reports real-time gross volume, 25% airline commission, 100% retained voucher treasury, marginal Jet-A1 fuel burn (`3.5%/h × flight hours × €1.10/kg`), net ancillary margin, and passenger savings vs airport excess fees.

Built with **Ruby on Rails 7.0** and **PostgreSQL 16**, accessible to **RGAA 4.1 / WCAG 2.1 Level AA**, hardened to **OWASP** standards (strict CSP, zero inline scripts/styles, `Rack::Attack`), and zero ExecJS dependency.

## Pre-Seeded Demo Accounts (`db/seeds.rb`)

| Persona | Email | Password |
| --- | --- | --- |
| Light Traveler (Seller — ASK) | `marie@example.com` | `Marie123!` |
| Heavy Traveler (Buyer — BID) | `pierre@example.com` | `Pierre123!` |
| Airline Revenue VP | `vp@airfrance-demo.com` | `Airline123!` |

## Local Development & Tests

```bash
bundle install
bin/rails db:create db:migrate db:seed
bin/rails zeitwerk:check
bin/rails test
bin/rails server
```
