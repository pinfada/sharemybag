require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Workspace
  class Application < Rails::Application
    config.load_defaults 7.0

    # English as the primary language
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :en
    config.i18n.available_locales = [:en]
    config.i18n.fallbacks = true
  end
end
