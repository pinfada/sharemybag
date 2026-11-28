require "uri"
require "ipaddr"

class AirlineConnector < ApplicationRecord
  PROVIDERS = %w[sandbox iata_ndc navitaire_rest webhook_rest].freeze
  AUTH_MODES = %w[sandbox oauth2_client_credentials oauth2_mtls hmac_bearer].freeze

  PROVIDER_LABELS = {
    "sandbox"        => "IATA Sandbox Simulator",
    "iata_ndc"       => "IATA NDC / ONE Order (Amadeus Altéa · Sabre)",
    "navitaire_rest" => "Navitaire New Skies REST (DotREZ)",
    "webhook_rest"   => "Universal Carrier Gateway (Signed REST/Webhook)"
  }.freeze

  BLOCKED_CIDRS = [
    IPAddr.new("127.0.0.0/8"),
    IPAddr.new("10.0.0.0/8"),
    IPAddr.new("172.16.0.0/12"),
    IPAddr.new("192.168.0.0/16"),
    IPAddr.new("169.254.0.0/16"),
    IPAddr.new("::1/128"),
    IPAddr.new("fc00::/7"),
    IPAddr.new("fe80::/10")
  ].freeze

  has_many :dcs_sync_events, dependent: :restrict_with_error

  before_validation :normalize_codes

  validates :airline_code, presence: true, uniqueness: { case_sensitive: false }, length: { in: 2..3 }
  validates :airline_name, presence: true, length: { maximum: 100 }
  validates :provider, inclusion: { in: PROVIDERS }
  validates :auth_mode, inclusion: { in: AUTH_MODES }
  validates :accounting_prefix, presence: true, format: { with: /\A\d{3}\z/, message: "must be a 3-digit IATA accounting prefix" }
  validates :timeout_seconds, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 30 }
  validate  :validate_api_base_url_security

  scope :active, -> { where(active: true) }

  def provider_label
    PROVIDER_LABELS[provider] || provider.humanize
  end

  def resolve_secret(ref)
    return nil if ref.blank?
    ENV[ref.to_s]
  end

  def webhook_signing_secret
    resolve_secret(webhook_signing_secret_ref)
  end

  def live_external?
    provider != "sandbox" && api_base_url.present? && resolve_secret(credentials_ref).present?
  end

  def simulated_settlement?
    provider == "sandbox" || URI.parse(api_base_url.to_s).host.to_s.end_with?(".example")
  end

  private

  def normalize_codes
    self.airline_code = airline_code.to_s.strip.upcase if airline_code.present?
  end

  def validate_api_base_url_security
    return if api_base_url.blank?

    uri = URI.parse(api_base_url)
    unless uri.is_a?(URI::HTTPS) && uri.host.present?
      errors.add(:api_base_url, "must be a valid HTTPS URL")
      return
    end

    host = uri.host.downcase
    if host == "localhost" || host.end_with?(".local", ".internal")
      errors.add(:api_base_url, "cannot target localhost or internal hostnames")
      return
    end

    begin
      ip = IPAddr.new(host)
      if BLOCKED_CIDRS.any? { |cidr| cidr.include?(ip) }
        errors.add(:api_base_url, "cannot target private, loopback, or cloud metadata IP ranges")
      end
    rescue IPAddr::InvalidAddressError
      # Public DNS hostname — allowed
    end
  rescue URI::InvalidURIError
    errors.add(:api_base_url, "is not a valid URL")
  end
end
