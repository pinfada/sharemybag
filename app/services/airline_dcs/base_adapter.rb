require "net/http"
require "json"
require "openssl"
require "uri"

module AirlineDcs
  class BaseAdapter
    attr_reader :connector

    def initialize(connector)
      @connector = connector
    end

    def issue_buyer_emd_a(trade:, booking:, idempotency_key:)
      raise NotImplementedError
    end

    def adjust_seller_allowance(trade:, booking:, idempotency_key:)
      raise NotImplementedError
    end

    def restore_seller_allowance(trade:, booking:, idempotency_key:)
      raise NotImplementedError
    end

    def issue_seller_voucher_emd_s(trade:, booking:, idempotency_key:)
      raise NotImplementedError
    end

    def void_emd(external_reference:, pnr_code:, idempotency_key:)
      raise NotImplementedError
    end

    protected

    def generate_iata_emd_number(seed_str)
      prefix = connector.accounting_prefix.presence || "057"
      digits = Digest::SHA256.hexdigest("#{prefix}:#{seed_str}").to_i(16).to_s.first(10).rjust(10, "0")
      "#{prefix}-#{digits}"
    end

    def post_json(path:, payload:, headers: {})
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      uri = URI.join("#{connector.api_base_url.to_s.chomp('/')}/", path.to_s.sub(%r{\A/}, ""))
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = connector.timeout_seconds
      http.read_timeout = connector.timeout_seconds

      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-Type"] = "application/json"
      req["Accept"] = "application/json"
      headers.each { |k, v| req[k] = v if v.present? }
      req.body = JSON.generate(payload)

      res = http.request(req)
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      parsed = JSON.parse(res.body) rescue { raw: res.body.to_s.first(300) }
      [res.code.to_i, parsed.is_a?(Hash) ? parsed : {}, elapsed_ms]
    rescue StandardError => e
      elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      [0, { error: e.message }, elapsed_ms]
    end
  end
end
