source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.0.5'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# permet de recuperer mes coordonnées géographiques d'un lieu
gem 'geocoder'
# permet d'inserer la google map dans rails
gem 'gmaps4rails'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem "letter_opener", :group => :development

gem 'bootstrap-social-rails'
gem 'bootstrap', '~> 4.3.1'
gem 'glyphicons-rails'
gem 'font-awesome-sass'
gem 'magnific-popup-rails'
gem 'rspec-its'
gem 'faker', '1.2.0'
gem 'will_paginate'
gem 'will_paginate-bootstrap'

# RailsAdmin is a Rails engine that provides an easy-to-use interface for managing your data.
gem 'rails_admin', '~> 1.3'

# Gestion sécurisé des clés API
gem 'figaro'

# Pour l'authentification de l'utilisateur 
gem 'omniauth-twitter'
gem 'omniauth-facebook'
gem 'omniauth-linkedin'
gem 'omniauth-github'

# Use jquery as the JavaScript library
gem 'activerecord-reset-pk-sequence'
gem 'database_cleaner', '~> 1.4.0'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'jquery-ui-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
gem 'bcrypt', '~> 3.1.7'

gem "font-awesome-rails"

# Explore your data with SQL. Easily create charts and dashboards, and share them with your team.
gem 'blazer'

source 'https://rails-assets.org' do
  gem "rails-assets-underscore"
end

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'selenium-webdriver'
  # Simulates how a user would interact with a website
  gem 'capybara'
  # Notification system for windows. Trying to be Growl
  gem 'rb-notifu'
  # library which can be used to monitor directories for changes
  #gem 'wdm'
  gem 'factory_bot_rails'
end

group :development do
  # Use sqlite3 as the database for Active Record
  #gem 'sqlite3'
  gem 'pg'
  
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :production do 
  #gem 'pg', '~> 0.18'
  gem 'pg'
  gem 'rails_12factor'
end
