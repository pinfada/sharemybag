# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ShareMyBag is a Rails 7.0.8 marketplace platform that connects travelers with senders for luggage transport services. The platform operates as a reverse auction system where senders post shipping requests and travelers bid to transport packages.

## Key Architecture Components

### Core Business Models

1. **Marketplace System (Reverse Auction)**
   - `ShippingRequest`: Senders post requests for package transport with departure/arrival cities, dates, weight
   - `Bid`: Travelers bid on shipping requests with their proposed prices
   - `KiloOffer`: Travelers can post available luggage space proactively
   - `Transaction`: Financial transactions between users
   - `ShipmentTracking`: Tracks package status through delivery lifecycle

2. **Trust & Verification System**
   - `IdentityVerification`: User identity verification with government ID
   - `Review`: Two-way review system between senders and travelers
   - Rating system with average ratings calculation

3. **Communication System**
   - `Conversation`: Direct messaging between users
   - `Message`: Individual messages within conversations
   - `Notification`: Real-time notifications for bids, messages, status changes

4. **Legacy Components** (from original app)
   - `Vol` (flights), `Bagage` (luggage), `Paquet` (packages)
   - Social features: `Micropost`, `Relationship` (following system)

## Development Commands

```bash
# Setup & Dependencies
bundle install                 # Install Ruby gems
rails db:create                # Create database
rails db:migrate               # Run migrations
rails db:seed                  # Load seed data

# Development Server
rails server                   # Start server on port 3000
rails c                        # Rails console for debugging

# Database Tasks
rails db:populate              # Fill database with sample data
rails db:reset                 # Drop, create, migrate, seed

# Testing
rails test                     # Run all tests
rails test test/models/        # Run model tests
rails test test/controllers/   # Run controller tests
rails test TEST=test/models/user_test.rb  # Run single test file

# Asset Management
rails assets:precompile        # Compile assets for production
rails assets:clean             # Remove compiled assets

# Custom Rake Tasks
rails db:populate              # Generate sample users, microposts, relationships
rails aeroport:populate        # Import airport data
rails vol:populate             # Import flight data
```

## Critical Security Implementations

### Authentication & Authorization
- BCrypt password hashing with complexity requirements (uppercase, lowercase, digit, min 8 chars)
- Session-based authentication with remember tokens (SHA256 digest)
- OAuth integration (Twitter, Facebook, GitHub) via OmniAuth
- CSRF protection enabled globally
- Secure headers configured via `config/initializers/security_headers.rb`

### Rate Limiting & Protection
- Rack::Attack middleware for rate limiting
- Admin panel at `/dashboard` (RailsAdmin) - requires admin flag
- Analytics dashboard at `/blazer` - requires authentication

### Validation Rules
- ShippingRequest: weight 0-50kg, future dates only, status workflow enforced
- Bid: amount must be positive, can't bid on own requests
- Transaction: enforces payment states and escrow logic
- Review: ratings 1-5, one review per transaction per user

## Database Configuration

- PostgreSQL for all environments
- Environment variables for credentials:
  - `DB_USERNAME`, `DB_PASSWORD`
  - `DB_NAME_DEV`, `DB_NAME_TEST`, `DB_NAME_PROD`
  - Production uses `DATABASE_URL`

## Environment Setup

Required environment variables (use Figaro gem - creates `config/application.yml`):
```yaml
# OAuth providers
TWITTER_KEY: "..."
TWITTER_SECRET: "..."
FACEBOOK_APP_ID: "..."
FACEBOOK_APP_SECRET: "..."
GITHUB_CLIENT_ID: "..."
GITHUB_CLIENT_SECRET: "..."

# Maps
GOOGLE_MAPS_API_KEY: "..."

# Database (for production)
DATABASE_URL: "..."
```

## Deployment Considerations

- Rails 12factor gem included for Heroku compatibility
- Asset pipeline configured with Sprockets + Sass
- Turbolinks enabled for SPA-like navigation
- Bootstrap 5.3 + Font Awesome for UI components
- Internationalization ready (rails-i18n, http_accept_language)

## Testing Framework

- Minitest (Rails default) for unit/integration tests
- Factory Bot for test data generation
- Database Cleaner for test isolation
- Capybara + Selenium for system tests
- No RSpec configuration (though gem is in Gemfile)

## Key Business Logic Locations

- **Bid acceptance workflow**: `ShippingRequest#accept_bid!` - handles transaction atomicity
- **User verification**: `User#verified?` - checks identity verification status
- **Rating calculation**: `User#average_rating` - aggregates review scores
- **Shipment lifecycle**: `ShipmentTracking` controller actions (hand_over, mark_in_transit, deliver, confirm)
- **Notification triggers**: Controllers create notifications on key events (bid placed, message sent, status change)