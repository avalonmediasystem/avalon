class Admin::ApplicationSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_settings

  def show
    authorize! :read, @app_settings
  end

  def update
    authorize! :edit, @app_settings

    respond_to do |format|
      if @app_settings.update(app_settings_params)
        format.html { redirect_back fallback_location: admin_application_settings_url, notice: "Settings successfully updated." }
      else
        format.html { redirect_back fallback_location: admin_application_settings_url, alert: @app_settings.errors.full_messages.to_sentence }
      end
    end
  end

  private

  def load_settings
    @app_settings = Admin::ApplicationSetting.instance
  end

  def app_settings_params
    params.require(:admin_application_setting).permit!
  end
end
