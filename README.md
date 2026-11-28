# ShareMyBag Exchange

**A smarter way to share baggage allowance.**

ShareMyBag Exchange helps airlines offer passengers a simple way to exchange unused checked baggage allowance with other travelers on the same flight. Passengers who need extra room can buy allowance, while those traveling light can receive a flight voucher for the allowance they share.

## How it works

1. Passengers on the same flight offer or request baggage allowance before departure.
2. Matching offers are brought together at an agreed price.
3. Once the airline confirms the exchange, the passengers' allowances and any voucher balance are updated.

Each passenger packs and checks their own bags. No physical items change hands between travelers. Exchanges are subject to airline approval and operational requirements.

## Built for airlines and travelers

- **For travelers:** a flexible way to find extra baggage allowance or make use of allowance they don't need.
- **For airlines:** a white-label experience that opens a new revenue opportunity and helps make better use of existing baggage allowances.
- **For airline teams:** a simulator to explore potential revenue and operating impacts, alongside tools for connecting to airline systems.

## Try the demo

[Explore the ShareMyBag demo](https://pinfada.github.io/sharemybag/)

The demo features travelers booked on flight AF718 from Paris to Dakar and an airline revenue manager.

| Demo role | Email | Password |
| --- | --- | --- |
| Traveler offering allowance | `marie@example.com` | `Marie123!` |
| Traveler looking for allowance | `pierre@example.com` | `Pierre123!` |
| Airline revenue manager | `vp@airfrance-demo.com` | `Airline123!` |

## Run locally

ShareMyBag is built with Ruby on Rails and PostgreSQL. With the required dependencies and database available, run:

```bash
bundle install
bin/rails db:create db:schema:load db:seed
bin/rails test
bin/rails server
```

For airline integration and settlement operations, see [Carrier settlement](docs/carrier-settlement.md).
