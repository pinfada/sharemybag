require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Workspace
  class Application < Rails::Application
    config.load_defaults 7.0

    # I18n configuration
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :fr
    config.i18n.available_locales = [:fr, :en, :es]
    config.i18n.fallbacks = [:en]
  end
end
