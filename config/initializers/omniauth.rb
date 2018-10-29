OmniAuth.config.logger = Rails.logger

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :twitter, "aNwaj0ptNQD7pyMvfsdojgOHW", "JeDzbaa8QBgznUQs8knmXWiMtI0s8B6Yv8DhF2DWnLtieh3pNQ"
  provider :github, "56f525b422295b6b829f", "62e942fe1b0fbb35c32d3abdaf15d99eb3a01fac"
  provider :facebook, "427092574104969", "5c86e212fa8173d58c2e01c9d3b268fd", 
  			{client_options: {
  				ssl: {ca_file: Rails.root.join('lib/assets/cacert.pem').to_s},
  				:site => 'https://graph.facebook.com/v2.0',
  				:authorize_url => "https://www.facebook.com/v2.0/dialog/oauth"
  				}
  			}
end