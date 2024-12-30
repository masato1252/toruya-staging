# frozen_string_literal: true

class Lines::UserBot::BookingsController < Lines::UserBotDashboardController
  def new
  end

  def page
    outcome = ::BookingPages::SmartCreate.run(attrs: {
      super_user_id: Current.business_owner.id,
      shop_id: Current.business_owner.shops.first.id,
    })

    redirect_to lines_user_bot_booking_page_path(business_owner_id: business_owner_id, id: outcome.result.id), notice: I18n.t("user_bot.dashboards.booking_page_creation.create_booking_page_successfully")
  end

  def available_options
    menu_result = ::Menus::CategoryGroup.run!(menu_options: shop_menus_options)
    outcome = ::BookingPages::AvailableBookingOptions.run(shop: Current.business_owner.shops.find(params[:shop_id]))

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
end
