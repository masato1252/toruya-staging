# frozen_string_literal: true

class Lines::UserBot::BookingsController < Lines::UserBotDashboardController
  include CrossAccountRedirect
  redirect_to_correct_owner_for :shops, param_key: :shop_id, only: [:available_options]

  def new
    if compat_read_data_plane?
      render :new_compat
      return
    end
  end

  def page
    if compat_read_data_plane?
      owner_id = compat_booking_owner_id
      body = params.permit(:shop_id, :menu_id, :booking_option_id, :new_booking_option_price,
                           :new_booking_option_tax_include, :ticket_quota, :ticket_expire_month,
                           :new_menu_name, :new_menu_minutes, :new_menu_online, :note,
                           :rich_menu_only).to_h
      result = compat_v1_post("/lines/user_bot/owner/#{owner_id}/bookings/page", body)
      return render_compat_booking_result(result)
    end

    shop = if params[:shop_id].present?
      Current.business_owner.shops.active.find(params[:shop_id])
    else
      Current.business_owner.shops.active.order(:id).first
    end

    outcome = ::BookingPages::SmartCreate.run(attrs: {
      super_user_id: Current.business_owner.id,
      shop_id: shop.id,
    })

    redirect_to lines_user_bot_booking_page_path(business_owner_id: business_owner_id, id: outcome.result.id), notice: I18n.t("user_bot.dashboards.booking_page_creation.create_booking_page_successfully")
  end

  def available_options
    if compat_read_data_plane?
      owner_id = compat_booking_owner_id
      payload = compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/bookings/available_options",
        { shop_id: params[:shop_id] }.compact
      )
      return render json: payload || { status: "failed", error_message: "予約メニューを取得できませんでした" },
                    status: (payload ? :ok : :bad_gateway)
    end

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

  private

  def compat_booking_owner_id
    resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
  end

  def render_compat_booking_result(result)
    if result&.dig("status") == "successful"
      render json: result
    else
      render json: result || { status: "failed", error_message: "予約ページの作成に失敗しました" },
             status: :unprocessable_entity
    end
  end
end
