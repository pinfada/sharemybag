source 'https://rubygems.org'

ruby '>= 3.2.3'

gem 'rails', '~> 7.0.8'
gem 'sprockets-rails'
gem 'dotenv-rails', groups: [:development, :test]
# Pas d'ExecJS (ni uglifier ni coffee-rails) pour compatibilité totale avec la sandbox railsbox.
gem 'sassc-rails'
gem 'pg', '~> 1.5'
gem 'puma', '~> 6.0'

# Frontend (Bootstrap 5.3 natif + Font Awesome, zéro jQuery / zéro Bootstrap 3 vendored)
gem 'bootstrap', '~> 5.3'
gem 'font-awesome-sass', '~> 6.0'

# Pagination & Base de données
gem 'will_paginate', '~> 4.0'
gem 'activerecord-reset-pk-sequence'

# Authentification & Sécurité
gem 'bcrypt', '~> 3.1'
gem 'rack-attack'

# Internationalisation
gem 'rails-i18n', '~> 7.0'

group :development, :test do
  # Rails 7.0 n'est pas compatible avec Minitest 6 (signature de Runnable#run modifiée)
  gem 'minitest', '~> 5.18'
  gem 'debug', platforms: %i[mri]
end

group :development do
  gem 'web-console'
end

group :production do
  gem 'rails_12factor'
end
