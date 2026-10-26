Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src :self
    policy.style_src :self, "https://fonts.googleapis.com"
    policy.font_src :self, "https://fonts.gstatic.com"
    policy.img_src :self, :data
    policy.connect_src :self, *ENV.fetch("CABLE_ORIGINS", "").split(",").map { |origin| origin.sub(/\Ahttp/, "ws") }
    policy.object_src :none
    policy.base_uri :self
    policy.form_action :self
    policy.frame_ancestors :none
    policy.upgrade_insecure_requests if Rails.env.production?
  end
  config.content_security_policy_nonce_generator = ->(request) { request.session[:csp_nonce] ||= SecureRandom.base64(24) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
