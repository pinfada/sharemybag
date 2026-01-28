OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, ENV.fetch("TWITTER_API_KEY", ""), ENV.fetch("TWITTER_API_SECRET", "")
  provider :github, ENV.fetch("GITHUB_CLIENT_ID", ""), ENV.fetch("GITHUB_CLIENT_SECRET", "")
  provider :facebook, ENV.fetch("FACEBOOK_APP_ID", ""), ENV.fetch("FACEBOOK_APP_SECRET", ""),
           { client_options: {
               ssl: { ca_file: Rails.root.join('lib/assets/cacert.pem').to_s },
               site: 'https://graph.facebook.com/v2.0',
               authorize_url: "https://www.facebook.com/v2.0/dialog/oauth"
             }
           }
end
