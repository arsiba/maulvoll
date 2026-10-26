InvisibleCaptcha.setup do |config|
  config.honeypots = [ :nickname_confirmation ]
  config.injectable_styles = false
  config.timestamp_enabled = !Rails.env.test?
  config.spinner_enabled = !Rails.env.test?
  config.secret = Rails.application.secret_key_base
end
