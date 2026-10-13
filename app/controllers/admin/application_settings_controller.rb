class Admin::ApplicationSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_settings

  def show
    authorize! :read, @app_settings
  end

  def update
    authorize! :update, @app_settings

    app_settings_params["bib_retriever"] = convert_to_hash("bib_retriever")
    app_settings_params["intercom"] = convert_to_hash("intercom")

    respond_to do |format|
      if @app_settings.update(app_settings_params)
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

  def convert_to_hash(field)
    return {} if app_settings_params[field].blank?
    JSON.parse(app_settings_params[field])
  rescue JSON::ParserError
    # The model validates the hash fields, so rely on that to block the save
    # and render the error message if improper data is provided.
    false
  end

  def app_settings_params
    params.require(:admin_application_setting).permit!
  end
end
