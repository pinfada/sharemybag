require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  config.assets.compile = false

  config.force_ssl = true
  config.log_level = :info

  config.log_tags = [:request_id]

  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.active_support.report_deprecations = false

  config.log_formatter = ::Logger::Formatter.new

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.active_record.dump_schema_after_migration = false

  # Email configuration
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              ENV.fetch('SMTP_HOST', 'smtp.gmail.com'),
    port:                 ENV.fetch('SMTP_PORT', 587).to_i,
    domain:               ENV.fetch('SMTP_DOMAIN', 'sharemybag.com'),
    user_name:            ENV['SMTP_USERNAME'],
    password:             ENV['SMTP_PASSWORD'],
    authentication:       'plain',
    enable_starttls_auto: true
  }
end
