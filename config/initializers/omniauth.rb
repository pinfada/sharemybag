OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, "bAetdt9eiT2zjwN1O4hTwg", "e3RCjBIS24GcTnYJTItYdAsZiPX7IAcO3pKSs2A75g"
  provider :github, "452f43a12d41643ca795", "a5fdc7349a74ddd3ce6c706794d09ae6ea897bcc"
  provider :facebook, "427092574104969", "5c86e212fa8173d58c2e01c9d3b268fd", 
  			{client_options: {
  				ssl: {ca_file: Rails.root.join('lib/assets/cacert.pem').to_s},
  				:site => 'https://graph.facebook.com/v2.0',
  				:authorize_url => "https://www.facebook.com/v2.0/dialog/oauth"
  				}
  			}
end