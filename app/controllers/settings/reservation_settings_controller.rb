class Settings::ReservationSettingsController < SettingsController
  def index
    @reservation_settings = super_user.reservation_settings
  end

  def new
    @reservation_setting = super_user.reservation_settings.new
  end
end
