class Settings::BookingOptionsController < SettingsController
  def index
    @booking_options = super_user.booking_options.includes(:menu_relations).order("id")
  end

  def new
    @booking_option = super_user.booking_options.new
  end

  def create
    outcome = BookingOptions::Create.run(user: super_user, attrs: params[:booking_option]&.permit!&.to_h)

    if outcome.valid?
      redirect_to settings_user_booking_options_path(super_user), notice: I18n.t("settings.staff_account.sent_message")
    else
      @booking_option = super_user.booking_options.new

      render :new
    end
  end
end
