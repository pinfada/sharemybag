class Rack::Attack
  # Throttle login attempts by IP address
  throttle('logins/ip', limit: 5, period: 300) do |req|
    if req.path == '/sessions' && req.post?
      req.ip
    end
  end

  # Throttle login attempts by email
  throttle('logins/email', limit: 5, period: 300) do |req|
    if req.path == '/sessions' && req.post?
      req.params.dig('session', 'email')&.downcase&.strip
    end
  end

  # Throttle signup attempts by IP
  throttle('signups/ip', limit: 3, period: 3600) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  # Throttle API requests
  throttle('api/ip', limit: 300, period: 300) do |req|
    req.ip
  end

  # Block suspicious requests
  blocklist('block bad IPs') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 300, bantime: 3600) do
      req.path == '/sessions' && req.post?
    end
  end

  # Custom throttle response
  self.throttled_responder = lambda do |env|
    [429, { 'Content-Type' => 'text/plain' }, ["Too many requests. Please retry later.\n"]]
  end
end
