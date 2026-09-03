class Admin::ApplicationSettingsController < ApplicationController
  before_action :authenticate_user!
  before_action :load_settings

  def index
    authorize! :read, @app_settings
  end

  private

  def load_settings
    @app_settings = Admin::ApplicationSetting.instance
  end
end
