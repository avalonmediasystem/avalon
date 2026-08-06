module IiifAuthService
  private

  def auth_service(quality = 'auto')
    {
      "@context": "http://iiif.io/api/auth/1/context.json",
      "@id": new_session_url,
      "@type": "AuthCookieService1",
      "confirmLabel": I18n.t('iiif.auth.confirmLabel'),
      "description": I18n.t('iiif.auth.description'),
      "failureDescription": I18n.t('iiif.auth.failureDescription'),
      "failureHeader": I18n.t('iiif.auth.failureHeader'),
      "header": I18n.t('iiif.auth.header'),
      "label": I18n.t('iiif.auth.label'),
      "profile": "http://iiif.io/api/auth/1/login",
      "service": [
        {
          "@id": hls_manifest_url(quality),
          "@type": "AuthProbeService1",
          "profile": "http://iiif.io/api/auth/1/probe"
        },
        {
          "@id": auth_token_url,
          "@type": "AuthTokenService1",
          "profile": "http://iiif.io/api/auth/1/token"
        },
        {
          "@id": destroy_session_url,
          "@type": "AuthLogoutService1",
          "label": I18n.t('iiif.auth.logoutLabel'),
          "profile": "http://iiif.io/api/auth/1/logout"
        }
      ]
    }
  end

  def auth2_service
    {
      "id": probe_url,
      "type": "AuthProbeService2",
      "errorNote": { "en": [I18n.t('iiif.auth.failureDescription')] },
      "errorHeading": { "en": [I18n.t('iiif.auth.failureHeader')] },
      "service": [
        {
          "id": new_session_url,
          "type": "AuthAccessService2",
          "confirmLabel": { "en": [I18n.t('iiif.auth.confirmLabel')] },
          "note": { "en": [I18n.t('iiif.auth.description')] },
          "heading": { "en": [I18n.t('iiif.auth.header')] },
          "label": { "en": [I18n.t('iiif.auth.label')] },
          "profile": "active",
          "service": [
            {
              "id": auth_token_url,
              "type": "AuthAccessTokenService2",
              "profile": "http://iiif.io/api/auth/1/token",
              "errorNote": { "en": [I18n.t('iiif.auth.failureDescription')] },
              "errorHeading": { "en": [I18n.t('iiif.auth.failureHeader')] }
            },
            {
              "id": destroy_session_url,
              "type": "AuthLogoutService2",
              "label": { "en": [I18n.t('iiif.auth.logoutLabel')] }
            }
          ]
        }
      ]
    }
  end

  def new_session_url
    Rails.application.routes.url_helpers.new_user_session_url(login_popup: 1)
  end

  def destroy_session_url
    Rails.application.routes.url_helpers.destroy_user_session_url
  end

  def auth_token_url
    Rails.application.routes.url_helpers.iiif_auth_token_url(id: master_file.id)
  end

  def probe_url
    Rails.application.routes.url_helpers.iiif_auth_probe_url(master_file.id)
  end

  def hls_manifest_url(quality)
    Rails.application.routes.url_helpers.hls_manifest_master_file_url(master_file.id, quality: quality)
  end
end
