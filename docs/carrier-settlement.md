# Carrier settlement

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
