class Lines::UserBot::BookingOptionsController < Lines::UserBotDashboardController
  before_action :authorize_booking_option

  def index
    @booking_options = super_user.booking_options.includes(:menus).order("id")
  end

  def show
    @booking_option = super_user.booking_options.find(params[:id])
    @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)
  end

  # def new
  #   @booking_option = super_user.booking_options.new
  #   @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)
  #   render :form
  # end
  #
  # def create
  #   outcome = BookingOptions::Save.run(booking_option: super_user.booking_options.new, attrs: params[:booking_option].permit!.to_h)
  #
  #   if outcome.valid?
  #     if session[:booking_settings_tour]
  #       redirect_to settings_user_booking_pages_path(super_user)
  #     else
  #       redirect_to settings_user_booking_options_path(super_user), notice: I18n.t("common.create_successfully_message")
  #     end
  #   else
  #     @booking_option = super_user.booking_options.new
  #     @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)
  #
  #     render :form
  #   end
  # end
  #
  def edit
    @booking_option = super_user.booking_options.find(params[:id])
    @attribute = params[:attribute]
    option_menu = @booking_option.booking_option_menus.find_by(menu_id: params[:menu_id])

    if option_menu
      @editing_menu = option_menu.attributes.slice("priority", "required_time", "menu_id").merge!(label: option_menu.menu.name)
    end

    @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)
  end

  def update
    @booking_option = super_user.booking_options.find(params[:id])

    outcome = BookingOptions::Update.run(booking_option: @booking_option, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    render json: {
      status: "successful",
      redirect_to: lines_user_bot_booking_option_path(@booking_option.id, anchor: params[:attribute])
    }
  end

  def reorder_menu_priority
    @booking_option = super_user.booking_options.find(params[:id])

    outcome = BookingOptions::Update.run(booking_option: @booking_option, attrs: params.permit!.to_h, update_attribute: "menus_priority")

    head :ok
  end

  def delete_menu
    @booking_option = super_user.booking_options.find(params[:id])

    @booking_option.booking_option_menus.find_by(menu_id: params[:menu_id]).destroy
    @booking_option.update(minutes: @booking_option.booking_option_menus.sum(:required_time))

    redirect_to lines_user_bot_booking_option_path(@booking_option.id, anchor: "new_menu")
  end

  def destroy
    booking_option = super_user.booking_options.find(params[:id])

    if booking_option.destroy
      redirect_to lines_user_bot_booking_options_path(super_user), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_booking_options_path(super_user)
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
