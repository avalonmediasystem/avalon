Rails.application.reloader.to_prepare do
  # LTI's third-party-initiated login (both 1.1's form_post launch and 1.3's
  # OIDC init) arrives as a cross-site POST from the LMS, which carries no
  # Avalon CSRF token to check. OmniAuth's authenticity check is a single
  # global callable (OmniAuth.config.request_validation_phase), not something
  # scopeable per-strategy via options, so we scope it here instead: run the
  # default check for every provider except :lti, matching what
  # Users::OmniauthCallbacksController#skip_before_action :verify_authenticity_token
  # already does for the same reason.
  default_validation = OmniAuth::AuthenticityTokenProtection
  OmniAuth.config.request_validation_phase = lambda do |env|
    strategy = env['omniauth.strategy']
    next if strategy && strategy.name == 'lti'

    default_validation.call(env)
  end
end
