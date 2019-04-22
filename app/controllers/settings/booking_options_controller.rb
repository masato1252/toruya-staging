class Settings::BookingOptionsController < SettingsController
  before_action :authorize_booking_option

  def index
    @booking_options = super_user.booking_options.includes(:menu_relations).order("id")
  end

  def new
    @booking_option = super_user.booking_options.new
    @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)
  end

  def create
    outcome = BookingOptions::Save.run(booking_option: super_user.booking_options.new, attrs: params[:booking_option].permit!.to_h)

    if outcome.valid?
      redirect_to settings_user_booking_options_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      @booking_option = super_user.booking_options.new
      @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)

      render :new
    end
  end

  def edit
    @booking_option = super_user.booking_options.find(params[:id])
    @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)
  end

  def update
    @booking_option = super_user.booking_options.find(params[:id])

    outcome = BookingOptions::Save.run(booking_option: @booking_option, attrs: params[:booking_option].permit!.to_h)

    if outcome.valid?
      redirect_to settings_user_booking_options_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)
      render :edit
    end
  end

  def destroy
    booking_option = super_user.booking_options.find(params[:id])

    if booking_option.destroy
      redirect_to settings_user_booking_options_path(super_user), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to settings_user_booking_options_path(super_user)
    end
  end

  private

  def menu_options
    super_user.menus.map do |menu|
      ::Options::MenuOption.new(id: menu.id, name: menu.display_name, minutes: menu.minutes, interval: menu.interval)
    end
  end

  def authorize_booking_option
    authorize! :manage, BookingOption
  end
end
