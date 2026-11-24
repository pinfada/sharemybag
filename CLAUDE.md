# CLAUDE.md

## Project Overview

ShareMyBag is a focused Ruby on Rails 7.0 + PostgreSQL application built around a single core feature: **peer-to-peer parcel transport via reverse auction**.

### Core Domain (8 Models)
- `User`: BCrypt authentication with complexity policy, SHA256 remember-token rotation, reputation metrics (`average_rating`, `completed_shipments_count`).
- `ShippingRequest`: Reverse auction parcel listing with euros↔cents conversion (`max_budget_euros`), mandatory `prohibited_items_acknowledged` attestation, SQL-LIKE escaped search scopes, and atomic `accept_bid!` (with row locks).
- `Bid`: Traveler price-per-kg offer (`price_per_kg_euros`), capacity validation, automatic total calculation, safe `withdraw!` transition.
- `ShipmentTracking`: Strict 5-step state machine (`created → handed_over → in_transit → delivered → confirmed`), cryptographic 8-char `handover_code` and `delivery_code` verified with `ActiveSupport::SecurityUtils.secure_compare`, strictly hidden from travelers in views.
- `Conversation` & `Message`: Direct contextual messaging between participants with bidirectional uniqueness.
- `Review`: Mutual 1–5 star reviews unlocked only after confirmed delivery; `reviewee` and `role` are strictly derived server-side in `ReviewsController`.
- `Notification`: Targeted alerts on bids, tracking transitions, messages, and reviews.

## Commands

```bash
bundle install
bin/rails db:create db:schema:load db:seed
bin/rails zeitwerk:check
bin/rails test
RAILS_ENV=production SECRET_KEY_BASE=test DATABASE_URL=postgres://postgres:postgres@127.0.0.1:5432/sharemybag_production bin/rails assets:precompile
```

## Security Standards Enforced
- OWASP HTTP headers (`config/initializers/security_headers.rb`) & strict CSP (`config/initializers/content_security_policy.rb`, zero inline scripts/styles).
- Hardened cookies (`HttpOnly`, `SameSite=Lax`, `Secure` in production) and `reset_session` on sign-in/sign-out.
- Open-redirect protection in `SessionsHelper#safe_return_path`.
- Rate limiting via `Rack::Attack` (`config/initializers/rack_attack.rb`).
- Sensitive parameter log filtering (`config/initializers/filter_parameter_logging.rb`).
- Zero ExecJS dependency so asset precompilation works on `railsbox` (i386 VM without Node).