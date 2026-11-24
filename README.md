# ShareMyBag

[![Try with railsbox](https://pinfada.github.io/tchopmygrinds/badge.svg)](https://pinfada.github.io/sharemybag/)

**ShareMyBag** connects parcel senders with travelers who have spare luggage allowance through a single, transparent **reverse auction** workflow:

1. **Post** — The sender describes their route, parcel weight, desired date, optional budget cap, and confirms the prohibited items safety pledge.
2. **Compare** — Travelers flying that route submit their price per kilo; total cost is calculated automatically.
3. **Track with secret codes** — Accepting one offer locks the request and generates two confidential 8-character codes (handover and delivery), visible only to the sender and verified in constant time on the server.
4. **Review** — Once receipt is confirmed, both participants publish a single verified review that builds lasting profile trust.

Built with **Ruby on Rails 7.0** and **PostgreSQL**, accessible to **RGAA 4.1 / WCAG 2.1 Level AA** standards, and zero ExecJS dependency (fully compatible with `railsbox`).

## Live Playable Demo

**→ [pinfada.github.io/sharemybag](https://pinfada.github.io/sharemybag/)**

Demo accounts pre-loaded by `db/seeds.rb`:

| Role | Email | Password |
| --- | --- | --- |
| Sender | `marie@example.com` | `Marie123!` |
| Traveler | `pierre@example.com` | `Pierre123!` |
| Demo | `demo@sharemybag.com` | `Demo123!` |

## Local Development

Requirements: Ruby ≥ 3.2.3 (`.ruby-version`: 3.3), PostgreSQL 16, `libpq-dev`.

```bash
bundle install
bin/rails db:create db:schema:load db:seed
bin/rails server
```

## Tests, Security & Accessibility

```bash
bin/rails zeitwerk:check
bin/rails test
```

The Minitest suite verifies:
- Core model invariants and strict state-machine transitions (`test/models/`),
- OWASP HTTP headers, strict CSP, HttpOnly/SameSite cookies, PII privacy, and anti-IDOR guards (`test/integration/security_and_auth_test.rb`, `test/integration/marketplace_authorization_test.rb`),
- RGAA 4.1 AA structural accessibility checks (`test/integration/rgaa_accessibility_and_i18n_test.rb`),
- End-to-end reverse auction workflow (`test/integration/end_to_end_reverse_auction_test.rb`).
