# frozen_string_literal: true

class Lines::UserBot::BookingOptionsController < Lines::UserBotDashboardController
  def index
    @booking_options = Current.business_owner.booking_options.includes(:menus).order("updated_at DESC")
  end

  def show
    @booking_option = Current.business_owner.booking_options.find(params[:id])
    all_menu_options = Current.business_owner.menus.map do |menu|
      ::Options::MenuOption.new(id: menu.id, name: menu.display_name, minutes: menu.minutes, interval: menu.interval, online: menu.online)
    end
    @menu_result = ::Menus::CategoryGroup.run!(menu_options: all_menu_options)
  end

  def edit
    @booking_option = Current.business_owner.booking_options.find(params[:id])
    @attribute = params[:attribute]
    option_menu = @booking_option.booking_option_menus.find_by(menu_id: params[:menu_id])

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
