class AirlineEconomicsService
  JET_FUEL_PRICE_EUR_PER_KG = 1.10

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
    voucher_adoption_percent: 70.0,
    avg_flight_duration_hours: 4.5,
    airport_excess_fee_euros: 15.0,
    fuel_burn_rate_per_kg_hour: 0.035
  )
    annual_flights = daily_flights.to_i * 365
    annual_kg = (annual_flights * avg_matched_kg_per_flight.to_f).round(1)
    gross_cents = (annual_kg * avg_spot_price_euros.to_f * 100.0).round
    commission_cents = (gross_cents * (commission_percent.to_f / 100.0)).round
    seller_payout_cents = gross_cents - commission_cents
    retained_voucher_cents = (seller_payout_cents * (voucher_adoption_percent.to_f / 100.0)).round

    fuel_kg = annual_kg * fuel_burn_rate_per_kg_hour.to_f * avg_flight_duration_hours.to_f
    fuel_cost_cents = (fuel_kg * JET_FUEL_PRICE_EUR_PER_KG * 100.0).round
    net_margin_cents = commission_cents - fuel_cost_cents

    savings_per_kg = [airport_excess_fee_euros.to_f - avg_spot_price_euros.to_f, 0.0].max
    passenger_savings_cents = (annual_kg * savings_per_kg * 100.0).round

    {
      annual_flights: annual_flights,
      annual_matched_kg: annual_kg,
      annual_gross_volume_cents: gross_cents,
      annual_commission_cents: commission_cents,
      annual_retained_voucher_cents: retained_voucher_cents,
      annual_total_cash_retained_cents: commission_cents + retained_voucher_cents,
      annual_fuel_cost_cents: fuel_cost_cents,
      annual_net_margin_cents: net_margin_cents,
      annual_passenger_savings_cents: passenger_savings_cents
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
      voucher_adoption_percent: total_trades > 0 ? ((voucher_trades.to_f / total_trades) * 100.0).round(1) : 0.0,
      avg_execution_price_cents: matched_kg > 0 ? (gross_cents / matched_kg).round : nil
    }
  end
  private_class_method :summarize_trades
end
