class AirlineEconomicsService
  JET_FUEL_PRICE_EUR_PER_KG = 1.10
  BELLY_CARGO_YIELD_CENTS_PER_KG = 280
  GHOST_ALLOWANCE_RATIO = 0.35
  CAPTURABLE_LIQUIDITY_RATIO = 0.25
  VOUCHER_REBOOKING_MARGIN_RATIO = 0.30
  CHECKIN_MINUTES_SAVED_PER_TRADE = 4.0
  AVG_KG_PER_TRADE = 10.0

  def self.trade_economics(flight:, quantity_kg:, execution_price_per_kg_cents:, payout_type: "voucher")
    qty = quantity_kg.to_f
    gross_cents = (qty * execution_price_per_kg_cents.to_i).round
    fee_cents = ((gross_cents * flight.airline_commission_bps.to_i) / 10_000.0).round
    seller_payout_cents = gross_cents - fee_cents

    burn_rate = flight.aircraft_type.fuel_burn_rate_per_kg_hour.to_f
    marginal_fuel_kg = qty * burn_rate * flight.flight_duration_hours.to_f
    fuel_cost_cents = (marginal_fuel_kg * JET_FUEL_PRICE_EUR_PER_KG * 100.0).round

    net_margin_cents = fee_cents - fuel_cost_cents
    airport_delta = [flight.airport_excess_fee_per_kg_cents.to_i - execution_price_per_kg_cents.to_i, 0].max
    buyer_savings_cents = (qty * airport_delta).round

    {
      gross_amount_cents: gross_cents,
      airline_fee_cents: fee_cents,
      seller_payout_cents: seller_payout_cents,
      estimated_fuel_cost_cents: fuel_cost_cents,
      airline_net_margin_cents: net_margin_cents,
      buyer_savings_cents: buyer_savings_cents,
      retained_voucher_cents: payout_type == "voucher" ? seller_payout_cents : 0
    }
  end

  def self.flight_summary(flight)
    trades = flight.kilo_trades
    summarize_trades(trades, flights_count: 1)
  end

  def self.flight_opportunity(flight)
    booked_kg = flight.base_booked_baggage_kg.to_f
    ghost_kg = (booked_kg * GHOST_ALLOWANCE_RATIO).round(1)
    used_kg = (booked_kg - ghost_kg).round(1)
    matched_kg = flight.total_matched_kg
    target_capturable_kg = (ghost_kg * CAPTURABLE_LIQUIDITY_RATIO).round(1)
    remaining_capturable_kg = [target_capturable_kg - matched_kg, 0.0].max.round(1)

    spot_cents = flight.spot_price_cents || (flight.airport_excess_fee_per_kg_cents * 0.5).round
    uncaptured_econ = trade_economics(
      flight: flight,
      quantity_kg: remaining_capturable_kg,
      execution_price_per_kg_cents: spot_cents,
      payout_type: "voucher"
    )

    max_payload = [flight.max_baggage_payload_kg, 1.0].max
    used_pct = ((used_kg / max_payload) * 100.0).clamp(0.0, 100.0).round(1)
    matched_pct = ((matched_kg / max_payload) * 100.0).clamp(0.0, 100.0).round(1)
    ghost_unmatched_kg = [ghost_kg - matched_kg, 0.0].max.round(1)
    ghost_pct = ((ghost_unmatched_kg / max_payload) * 100.0).clamp(0.0, 100.0 - used_pct - matched_pct).round(1)

    {
      booked_baggage_kg: booked_kg.round(1),
      used_baggage_kg: used_kg,
      ghost_allowance_kg: ghost_kg,
      ghost_unmatched_kg: ghost_unmatched_kg,
      matched_kg: matched_kg,
      capturable_kg: remaining_capturable_kg,
      uncaptured_net_margin_cents: uncaptured_econ[:airline_net_margin_cents],
      uncaptured_retained_voucher_cents: uncaptured_econ[:retained_voucher_cents],
      belly_cargo_yield_per_kg_cents: BELLY_CARGO_YIELD_CENTS_PER_KG,
      exchange_gross_yield_per_kg_cents: spot_cents,
      yield_multiplier_vs_cargo: (spot_cents.to_f / BELLY_CARGO_YIELD_CENTS_PER_KG).round(1),
      checkin_minutes_saved: (flight.kilo_trades.count * CHECKIN_MINUTES_SAVED_PER_TRADE).round,
      used_percent: used_pct,
      ghost_percent: ghost_pct,
      matched_percent: matched_pct
    }
  end

  def self.fleet_summary(flights_scope = Flight.all)
    flight_ids = flights_scope.reorder(nil).distinct.pluck(:id)
    trades = KiloTrade.where(flight_id: flight_ids)
    summarize_trades(trades, flights_count: flight_ids.size)
  end

  def self.annual_fleet_projection(
    daily_flights:,
    avg_matched_kg_per_flight:,
    avg_spot_price_euros: 7.5,
    commission_percent: 25.0,
    voucher_adoption_percent: 75.0,
    voucher_redemption_percent: 75.0,
    avg_flight_duration_hours: 4.5,
    airport_excess_fee_euros: 15.0,
    fuel_burn_rate_per_kg_hour: 0.035,
    cannibalization_percent: 6.0,
    booking_cannibalization_percent: 15.0,
    preflight_bag_fee_euros: 10.0,
    unused_allowance_percent: 35.0
  )
    annual_flights = daily_flights.to_i * 365
    unused_scale = unused_allowance_percent.to_f / (GHOST_ALLOWANCE_RATIO * 100.0)
    effective_kg_per_flight = avg_matched_kg_per_flight.to_f * unused_scale
    annual_kg = (annual_flights * effective_kg_per_flight).round(1)

    gross_cents = (annual_kg * avg_spot_price_euros.to_f * 100.0).round
    commission_cents = (gross_cents * (commission_percent.to_f / 100.0)).round
    seller_payout_cents = gross_cents - commission_cents
    retained_voucher_cents = (seller_payout_cents * (voucher_adoption_percent.to_f / 100.0)).round
    voucher_rebooking_margin_cents = (retained_voucher_cents * (voucher_redemption_percent.to_f / 100.0) * VOUCHER_REBOOKING_MARGIN_RATIO).round

    fuel_per_kg_euros = fuel_burn_rate_per_kg_hour.to_f * avg_flight_duration_hours.to_f * JET_FUEL_PRICE_EUR_PER_KG
    fuel_cost_cents = (annual_kg * fuel_per_kg_euros * 100.0).round
    net_margin_cents = commission_cents - fuel_cost_cents

    # Counterfactual cannibalization: the physical bag flies in BOTH worlds, so fuel is identical
    # and MUST NOT be credited back against foregone ancillary bag revenue.
    booking_cannib_kg = annual_kg * (booking_cannibalization_percent.to_f / 100.0)
    booking_cannib_deduction_cents = (booking_cannib_kg * preflight_bag_fee_euros.to_f * 100.0).round

    counter_cannib_kg = annual_kg * (cannibalization_percent.to_f / 100.0)
    counter_cannib_deduction_cents = (counter_cannib_kg * airport_excess_fee_euros.to_f * 100.0).round

    ex_voucher_profit_cents = net_margin_cents - booking_cannib_deduction_cents - counter_cannib_deduction_cents
    incremental_profit_cents = ex_voucher_profit_cents + voucher_rebooking_margin_cents

    # Sign-aware conservative floor: always 30% worse than base (lower profit when positive, deeper loss when negative)
    incremental_profit_low_cents = if incremental_profit_cents >= 0
      (incremental_profit_cents * 0.70).round
    else
      (incremental_profit_cents * 1.30).round
    end

    savings_per_kg = [airport_excess_fee_euros.to_f - avg_spot_price_euros.to_f, 0.0].max
    passenger_savings_cents = (annual_kg * savings_per_kg * 100.0).round
    annual_checkin_hours_saved = ((annual_kg / AVG_KG_PER_TRADE) * CHECKIN_MINUTES_SAVED_PER_TRADE / 60.0).round

    {
      annual_flights: annual_flights,
      annual_matched_kg: annual_kg,
      annual_gross_volume_cents: gross_cents,
      annual_commission_cents: commission_cents,
      annual_retained_voucher_cents: retained_voucher_cents,
      annual_voucher_rebooking_margin_cents: voucher_rebooking_margin_cents,
      annual_total_cash_retained_cents: commission_cents + retained_voucher_cents,
      annual_fuel_cost_cents: fuel_cost_cents,
      annual_net_margin_cents: net_margin_cents,
      annual_booking_cannibalization_deduction_cents: booking_cannib_deduction_cents,
      annual_cannibalization_deduction_cents: counter_cannib_deduction_cents,
      annual_ex_voucher_profit_cents: ex_voucher_profit_cents,
      annual_incremental_profit_low_cents: incremental_profit_low_cents,
      annual_incremental_profit_cents: incremental_profit_cents,
      annual_passenger_savings_cents: passenger_savings_cents,
      annual_checkin_hours_saved: annual_checkin_hours_saved
    }
  end

  def self.summarize_trades(trades, flights_count:)
    matched_kg = trades.sum(:quantity_kg).to_f.round(2)
    gross_cents = trades.sum(:gross_amount_cents).to_i
    commission_cents = trades.sum(:airline_fee_cents).to_i
    fuel_cost_cents = trades.sum(:estimated_fuel_cost_cents).to_i
    net_margin_cents = trades.sum(:airline_net_margin_cents).to_i
    passenger_savings_cents = trades.sum(:buyer_savings_cents).to_i
    retained_voucher_cents = trades.where(payout_type: "voucher").sum(:seller_payout_cents).to_i
    voucher_trades = trades.where(payout_type: "voucher").count
    total_trades = trades.count

    {
      flights_count: flights_count,
      trades_count: total_trades,
      matched_kg: matched_kg,
      gross_volume_cents: gross_cents,
      airline_commission_cents: commission_cents,
      retained_voucher_cents: retained_voucher_cents,
      total_cash_retained_cents: commission_cents + retained_voucher_cents,
      estimated_fuel_cost_cents: fuel_cost_cents,
      airline_net_margin_cents: net_margin_cents,
      passenger_savings_cents: passenger_savings_cents,
      checkin_minutes_saved: (total_trades * CHECKIN_MINUTES_SAVED_PER_TRADE).round,
      voucher_adoption_percent: total_trades > 0 ? ((voucher_trades.to_f / total_trades) * 100.0).round(1) : 0.0,
      avg_execution_price_cents: matched_kg > 0 ? (gross_cents / matched_kg).round : nil
    }
  end
  private_class_method :summarize_trades
end
