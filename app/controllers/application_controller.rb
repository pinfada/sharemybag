class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include ApplicationHelper
  include SessionsHelper

  before_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  private

  def set_locale
    I18n.locale = :en
  end

  def handle_not_found
    flash[:error] = t('common.not_found')
    redirect_to root_url
  end
end
