module SessionsHelper
  def sign_in(user)
    return_to = safe_return_path(session[:return_to])
    reset_session
    session[:return_to] = return_to if return_to.present?

    raw_token = User.new_remember_token
    cookies[:remember_token] = {
      value: raw_token,
      expires: 14.days.from_now,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }
    user.update_column(:remember_token, User.digest(raw_token))
    self.current_user = user
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    return @current_user if defined?(@current_user)

    raw_token = cookies[:remember_token]
    digest = User.digest(raw_token)
    @current_user = digest.present? ? User.find_by(remember_token: digest) : nil
  end

  def signed_in?
    current_user.present?
  end

  def current_user?(user)
    user.present? && user == current_user
  end

  def signed_in_user
    return if signed_in?

    store_location
    flash[:notice] = t('auth.sign_in_required')
    redirect_to signin_url
  end

  def sign_out
    if current_user
      current_user.update_column(:remember_token, User.digest(User.new_remember_token))
    end
    cookies.delete(:remember_token)
    reset_session
    @current_user = nil
  end

  def redirect_back_or(default)
    destination = safe_return_path(session.delete(:return_to)) || default
    redirect_to(destination)
  end

  def store_location
    return unless request.get? && !request.xhr?

    path = request.fullpath
    session[:return_to] = path if safe_return_path(path).present?
  end

  private

  def safe_return_path(path)
    return nil if path.blank?
    return nil unless path.start_with?('/') && !path.start_with?('//')
    path
  end
end
