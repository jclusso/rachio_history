class SettingsController < ApplicationController
  def show
    @setting = Setting.current
  end

  def update
    @setting = Setting.current
    @setting.rachio_api_key = params.expect(setting: [ :rachio_api_key ])[:rachio_api_key].strip

    if @setting.save
      redirect_to settings_path, notice: "Rachio API key saved."
    else
      render :show, status: :unprocessable_entity
    end
  end
end
