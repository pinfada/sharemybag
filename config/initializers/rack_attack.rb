class Rack::Attack
  # Disabled by default in test environment (can be explicitly enabled in security specs)
  self.enabled = !Rails.env.test?

  # Anti-brute-force on login (by IP)
  throttle("logins/ip", limit: 10, period: 5.minutes) do |req|
    req.ip if req.path == "/sessions" && req.post?
  end

  # Anti-brute-force on login (by normalized email)
  throttle("logins/email", limit: 5, period: 5.minutes) do |req|
    if req.path == "/sessions" && req.post?
      req.params.dig("session", "email").to_s.downcase.strip.presence
    end
  end

  # Account creation throttling (by IP)
  throttle("signups/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/users" && req.post?
  end

  # Order book anti-spam / anti-flooding protection (by IP)
  throttle("orders/ip", limit: 30, period: 5.minutes) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/flights/\d+/kilo_orders\z})
  end

  # Global IP rate limit
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets")
  end

  self.throttled_responder = lambda do |_request|
    [
      429,
      { "Content-Type" => "text/plain; charset=utf-8" },
      ["Too many requests. Please wait a moment and try again.\n"]
    ]
  end
end
