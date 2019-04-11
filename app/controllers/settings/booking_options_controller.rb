class Settings::BookingOptionsController < SettingsController
  def index
    @booking_options = super_user.booking_options.includes(:menu_relations).order("id")
  end
end
