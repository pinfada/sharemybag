class Rack::Attack
  # Désactivé par défaut en environnement de test (activable explicitement dans les tests de sécurité)
  self.enabled = !Rails.env.test?

  # Anti-brute-force sur la connexion (par IP)
  throttle('logins/ip', limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == '/sessions' && req.post?
  end

  # Anti-brute-force sur la connexion (par email normalisé)
  throttle('logins/email', limit: 5, period: 5.minutes) do |req|
    if req.path == '/sessions' && req.post?
      req.params.dig('session', 'email').to_s.downcase.strip.presence
    end
  end

  # Limitation des créations de compte (par IP)
  throttle('signups/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path == '/users' && req.post?
  end

  # Limitation des soumissions de codes remise/livraison (anti-énumération)
  throttle('tracking_codes/ip', limit: 10, period: 5.minutes) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/shipment_trackings/\d+/(hand_over|deliver)\z})
  end

  # Limitation globale par IP
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets')
  end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { 'Content-Type' => 'text/plain; charset=utf-8' },
      ["Too many requests. Please wait a moment and try again.\n"]
    ]
  end
end
