OmniAuth.config.logger = Rails.logger
OmniAuth.config.allowed_request_methods = [:post, :get]

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :github, ENV.fetch("GITHUB_CLIENT_ID", ""), ENV.fetch("GITHUB_CLIENT_SECRET", ""),
           scope: "user:email"
  provider :facebook, ENV.fetch("FACEBOOK_APP_ID", ""), ENV.fetch("FACEBOOK_APP_SECRET", ""),
           scope: "email"
end
