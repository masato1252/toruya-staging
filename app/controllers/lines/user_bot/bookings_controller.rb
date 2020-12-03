class Lines::UserBot::BookingsController < Lines::UserBotDashboardController
  def new
    @booking_page = super_user.booking_pages.new
    @shop = super_user.shops.count == 1 ? super_user.shops.first : nil
  end

  def page
    outcome = BookingPages::SmartCreate.run(attrs: params[:booking].permit!.to_h)

    render json: json_response(outcome, { booking_page_id: outcome.result&.id })
  end

  def available_options
    menu_result = ::Menus::CategoryGroup.run!(menu_options: shop_menus_options)
    outcome = BookingPages::AvailableBookingOptions.run(shop: shop)

    shop_booking_options = outcome.result.map do |option|
      view_context.custom_option(view_context.booking_option_item(option))
    end

    render json: json_response(
      outcome, {
      menus: view_context.menu_group_options(menu_result[:category_with_menu_options], :minutes, :interval, :min_staffs_number),
        booking_options: shop_booking_options
    }
    )
  end

  private

  def shop
    @shop ||= super_user.shops.find(params[:shop_id])
  end
end
