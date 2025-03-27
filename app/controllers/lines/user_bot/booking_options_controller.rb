# frozen_string_literal: true

class Lines::UserBot::BookingOptionsController < Lines::UserBotDashboardController
  def new
    @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)
    @options = ::BookingPages::AvailableBookingOptions.run!(shop: Current.business_owner.shops.first)
    @booking_pages = Current.business_owner.booking_pages.order("updated_at DESC").end_yet.filter_map { |booking_page| booking_page if !booking_page.ended? }
  end

  def create
    outcome = ::BookingOptions::Create.run(params.permit!.to_h.merge(user: Current.business_owner))

    if outcome.valid?
      flash[:success] = I18n.t("common.create_successfully_message")
    else
      flash[:error] = I18n.t("common.something_went_wrong_message")
    end

    if outcome.valid? && outcome.result&.id
      render json: json_response(outcome, { redirect_to: lines_user_bot_booking_page_path(outcome.result.id, business_owner_id: business_owner_id) })
    else
      render json: json_response(outcome, { redirect_to: lines_user_bot_booking_options_path(business_owner_id: business_owner_id) })
    end
  end

  def index
    @booking_options = Current.business_owner.booking_options.includes(:menus).order("updated_at DESC")
  end

  def show
    @booking_option = Current.business_owner.booking_options.find(params[:id])
    all_menu_options = Current.business_owner.menus.map do |menu|
      ::Options::MenuOption.new(id: menu.id, name: menu.display_name, minutes: menu.minutes, interval: menu.interval, online: menu.online)
    end
    @menu_result = ::Menus::CategoryGroup.run!(menu_options: all_menu_options)
    set_up_previous_cookie("booking_page_id", params[:booking_page_id]) if params[:booking_page_id]
    clean_previous_cookie("booking_option_id")
  end

  def edit
    @booking_option = Current.business_owner.booking_options.find(params[:id])
    @attribute = params[:attribute]
    option_menu = @booking_option.booking_option_menus.find_by(menu_id: params[:menu_id])
    @booking_pages = Current.business_owner.booking_pages.normal.order("updated_at DESC")

    if option_menu
      @editing_menu = option_menu.attributes.slice("priority", "required_time", "menu_id").merge!(label: option_menu.menu.name)
    end

    @menu_result = ::Menus::CategoryGroup.run!(menu_options: menu_options)
  end

  def update
    @booking_option = Current.business_owner.booking_options.find(params[:id])

    outcome = BookingOptions::Update.run(booking_option: @booking_option, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: lines_user_bot_booking_option_path(business_owner_id, @booking_option.id, anchor: params[:attribute]) })
  end

  def reorder_menu_priority
    @booking_option = Current.business_owner.booking_options.find(params[:id])

    outcome = BookingOptions::Update.run(booking_option: @booking_option, attrs: params.permit!.to_h, update_attribute: "menus_priority")

    head :ok
  end

  def delete_menu
    @booking_option = Current.business_owner.booking_options.find(params[:id])

    @booking_option.booking_option_menus.find_by(menu_id: params[:menu_id])&.destroy
    @booking_option.update(minutes: @booking_option.booking_option_menus.sum(:required_time))

    redirect_to lines_user_bot_booking_option_path(business_owner_id, @booking_option.id, anchor: "new_menu")
  end

  def destroy
    booking_option = Current.business_owner.booking_options.find(params[:id])

    outcome = BookingOptions::Delete.run(booking_option: booking_option)

    if outcome.valid?
      redirect_to lines_user_bot_booking_options_path(business_owner_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_booking_option_path(business_owner_id, booking_option), flash: { alert: outcome.errors.full_messages.join(", ") }
    end
  end

  private

  def menu_options
    Current.business_owner.menus.map do |menu|
      if menu.shop_menus.exists?
        ::Options::MenuOption.new(id: menu.id, name: menu.display_name, minutes: menu.minutes, interval: menu.interval, online: menu.online)
      end
    end.compact
  end
end
