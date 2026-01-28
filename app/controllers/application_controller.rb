class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper
  include SessionsHelper
  include VolsHelper

  before_action :set_locale

  private

  def set_locale
    I18n.locale = params[:locale] ||
                  (current_user&.locale if respond_to?(:current_user, true)) ||
                  extract_locale_from_accept_language_header ||
                  I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
    return nil unless accept_language
    locale = accept_language.scan(/^[a-z]{2}/).first&.to_sym
    I18n.available_locales.include?(locale) ? locale : nil
  end

  def default_url_options
    { locale: I18n.locale == I18n.default_locale ? nil : I18n.locale }
  end
end
