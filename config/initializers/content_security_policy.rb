# Be sure to restart your server when you modify this file.

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none

    # Allow scripts from both production domains
    policy.script_src :self, :https, "https://app.echosight.io", "https://echosight-production-web-service.onrender.com"
    policy.style_src :self, :https, "https://app.echosight.io", "https://echosight-production-web-service.onrender.com"

    # You may need to enable this in production as well depending on your setup.
    policy.script_src *policy.script_src, :blob if Rails.env.test?

    # Allow styles from both production domains
    policy.style_src :self, :https, "https://app.echosight.io", "https://echosight-production-web-service.onrender.com"

    # Specify URI for violation reports if needed
    # policy.report_uri "/csp-violation-report-endpoint"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
