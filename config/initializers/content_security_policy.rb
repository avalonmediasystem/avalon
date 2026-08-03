# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # Rails defaults
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"

    # Custom policies
    # JQuery requires this for compatibility with Firefox
    # TODO: Test removal after JQuery fully excised
    policy.script_src_attr :unsafe_inline
    # There are many inline styles that are difficult, or unable, to provide
    # the nonce value for. Leave unsafe for now.
    # TODO: Clean up inline styles and provide nonce for any that cant be changed
    policy.style_src   :unsafe_inline, :self, :https
    # Blob required for media streaming. worker_src from firefox, media_src from chrome
    policy.media_src   :self, :https, :blob
    policy.worker_src  :self, :https, :blob
    if Rails.env.development?
      # :http is set for convenience in dev environment.
      policy.connect_src :self, :http
      # unsafe_eval is necessary for dev environment. DO NOT enable in prod.
      policy.script_src  :self, :https, :unsafe_eval
    else
      policy.connect_src :self, :https
      policy.script_src  :self, :https
    end
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  # TODO: Assess feasibility of adding stlye-src to nonce directives
  config.content_security_policy_nonce_directives = %w(script-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
