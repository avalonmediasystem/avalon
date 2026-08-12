# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    # Rails defaults
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.object_src  :none
    # Specify URI for violation reports
    # policy.report_uri "/csp-violation-report-endpoint"

    # Custom policies
    # JQuery requires this for compatibility with Firefox
    # TODO: Test removal after JQuery fully excised
    policy.script_src_attr :unsafe_inline
    # Video.js generates a few style elements dynamically. To handle this we have to
    # either keep :unsafe_inline, monkey patch document.prototype.createElement,
    # or use hashes here. Hashes seem to be the overall most secure option, but does
    # have the downside of needing to be kept up to date when Video.js changes.
    policy.style_src   :self, :https, :unsafe_hashes, 'sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=',
      'sha256-wPXhisdsFu1DtHYH1D9W5isSGqS5vIPn6QJWSNLqfCM=', 'sha256-p/Gj9EBmerW5NLyLxdY9KdArmeYHT4hQCPXlruAJ/WA=',
      'sha256-nTLBTH8WUTkIIoYPCoe0Ml8nMCdu5XXfFeZihPe/kp8='
    # Blob required for media streaming. worker_src from firefox, media_src from chrome
    policy.media_src   :self, :https, :blob
    policy.worker_src  :self, :https, :blob
    # Blob required for image upload/cropping
    policy.img_src     :self, :https, :data, :blob
    if Rails.env.development?
      # :http is set for convenience in dev environment. :blob required for poster upload
      policy.connect_src :self, :http, :blob
      # unsafe_eval is necessary for dev environment. DO NOT enable in prod.
      policy.script_src  :self, :https, :unsafe_eval
      # react-dom-client uses unsafe inlines for dev env
      policy.style_src_attr :unsafe_inline
    else
      # blob required for poster image upload
      policy.connect_src :self, :https, :blob
      policy.script_src  :self, :https
    end
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w(script-src style-src)

  # Report violations without enforcing the policy.
  # config.content_security_policy_report_only = true
end
