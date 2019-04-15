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
      redirect_to settings_user_booking_options_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      @booking_option = super_user.booking_options.new

      render :new
    end
  end

  def edit
    @booking_option = super_user.booking_options.find(params[:id])
  end

  def update
    @booking_option = super_user.booking_options.find(params[:id])
    outcome = BookingOptions::Update.run(booking_option: @booking_option, attrs: params[:booking_option]&.permit!&.to_h)

    if outcome.valid?
      redirect_to settings_user_booking_options_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      render :edit
    end
  end
end
