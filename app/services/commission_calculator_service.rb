class CommissionCalculatorService
  PLATFORM_FEE_RATE = 0.15
  STRIPE_FIXED_FEE_CENTS = 25 # 0.25€ Stripe fixed fee
  STRIPE_PERCENTAGE_FEE = 0.014 # 1.4% for EU cards

  # Stripe fees vary by region
  STRIPE_RATES = {
    'EU' => { percentage: 0.014, fixed_cents: 25 },
    'UK' => { percentage: 0.014, fixed_cents: 20 },
    'US' => { percentage: 0.029, fixed_cents: 30 },
    'DEFAULT' => { percentage: 0.029, fixed_cents: 30 }
  }.freeze

  CURRENCY_MINIMUMS = {
    'EUR' => 1000,
    'USD' => 1000,
    'GBP' => 1000,
    'XOF' => 5000,
    'XAF' => 5000
  }.freeze

  def initialize(amount_cents:, currency: 'EUR', region: 'EU')
    @amount_cents = amount_cents
    @currency = currency
    @region = region
  end

  def calculate
    platform_fee = (@amount_cents * PLATFORM_FEE_RATE).round
    stripe_rate = STRIPE_RATES[@region] || STRIPE_RATES['DEFAULT']
    stripe_fee = (@amount_cents * stripe_rate[:percentage] + stripe_rate[:fixed_cents]).round
    net_platform_fee = platform_fee - stripe_fee
    traveler_payout = @amount_cents - platform_fee

    {
      amount_cents: @amount_cents,
      currency: @currency,
      platform_fee_cents: platform_fee,
      stripe_fee_cents: stripe_fee,
      net_platform_fee_cents: [net_platform_fee, 0].max,
      traveler_payout_cents: traveler_payout,
      platform_fee_rate: PLATFORM_FEE_RATE,
      minimum_amount_cents: CURRENCY_MINIMUMS[@currency] || 1000
    }
  end

  def self.for_bid(bid)
    amount = bid.total_price_cents
    new(amount_cents: amount, currency: bid.currency).calculate
  end

  def self.minimum_for_currency(currency)
    CURRENCY_MINIMUMS[currency] || 1000
  end
end
