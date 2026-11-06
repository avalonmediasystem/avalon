class Admin::ApplicationSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_settings

  def show
    authorize! :read, @app_settings
  end

  def update
    authorize! :update, @app_settings

    respond_to do |format|
      if @app_settings.update(update_params)
        format.html { redirect_back fallback_location: admin_application_settings_url, notice: "Settings successfully updated" }
      else
        format.html { redirect_back fallback_location: admin_application_settings_url, flash: { error: "Settings update failed: #{@app_settings.errors.full_messages.to_sentence}" } }
      end
    end
  end

  private

  def load_settings
    @app_settings = Admin::ApplicationSetting.instance
  end

  def convert_to_hash(field, settings_params)
    return {} if settings_params[field].blank?
    JSON.parse(settings_params[field])
  rescue JSON::ParserError
    # The model validates the hash fields, so rely on that to block the save
    # and render the error message if improper data is provided.
    false
  end

  def update_params
    payload = app_settings_params
    payload[:bib_retriever] = convert_to_hash(:bib_retriever, payload)
    payload[:intercom] = convert_to_hash(:intercom, payload)

    payload
  end

  def app_settings_params
    params.require(:admin_application_setting).permit(
      :name, :google_analytics_tracking_id, :bib_retriever, :intercom,
      :repository_read_only_mode, :repository_read_only_mode_message,
      accessibility_compliance_attributes: [:enforce, :compliance_date],
      caption_default_attributes: [:language, :name],
      controlled_digital_lending_attributes: [:enable, :collections_enabled, :default_lending_period],
      application_flash_message_attributes: [:type, :message],
      home_page_attributes: [:featured_collections, :carousel_collections],
      master_file_management_attributes: [:strategy, :path],
      recaptcha_attributes: [:site_key, :secret_key, :type, v3: [:action, :minimum_score]],
      supplemental_files_proxy_attributes: [:proxy],
      waveform_attributes: [:player_width, :finest_zoom, :sample_rate]
    )
  end
end
