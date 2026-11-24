# Filtrage des paramètres sensibles dans les logs applicatifs
Rails.application.config.filter_parameters += %i[
  password
  password_confirmation
  remember_token
  handover_code
  delivery_code
  code
  token
  secret
  _key
  crypt
  salt
  certificate
  otp
]
