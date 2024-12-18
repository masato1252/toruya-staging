# frozen_string_literal: true

class Lines::UserBot::Settings::MenusController < Lines::UserBotDashboardController
  def index
    @menus = Current.business_owner.menus.order("updated_at DESC")
  end

  def show
    @menu = Current.business_owner.menus.find(params[:id])

    @menu_shops = @menu.shop_menus.includes(:shop)
    @staffs = @menu.staff_menus.includes(:staff).map(&:staff)
    set_up_previous_cookie("booking_option_id", params[:booking_option_id]) if params[:booking_option_id]
    clean_previous_cookie("menu_id")
  end

  def edit
    @menu = Current.business_owner.menus.find(params[:id])

    case params[:attribute]
    when "menu_shops"
      shop_menus = @menu.shop_menus.includes(:shop).to_a
      @menu_shops_options = Current.business_owner.shops.map do |shop|
        if shop_menu = shop_menus.find { |shop_menu| shop_menu.shop_id == shop.id }
          Option.new(name: shop.display_name, shop_id: shop.id, max_seat_number: shop_menu.max_seat_number, checked: true)
        else
          Option.new(name: shop.display_name, shop_id: shop.id, max_seat_number: "", checked: false)
        end
      end
    when "menu_staffs"
      menu_staffs = @menu.menu_staffs.includes(:staff).to_a
      @menu_staffs_options = Current.business_owner.staffs.map do |staff|
        if menu_staff = menu_staffs.find { |menu_staff| menu_staff.staff_id == staff.id }
          Option.new(name: staff.name, staff_id: staff.id, max_customers: menu_staff.max_customers, checked: true)
        else
          Option.new(name: staff.name, staff_id: staff.id, max_customers: "", checked: false)
        end
      end
    end
  end

  def update
    menu = Current.business_owner.menus.find(params[:id])
    outcome = ::Menus::UpdateAttribute.run(menu: menu, attrs: params.permit!.to_h, update_attribute: params[:attribute])

    return_json_response(outcome, { redirect_to: params[:back_path] || lines_user_bot_settings_menu_path(business_owner_id, params[:id], anchor: params[:attribute]) })
  end

  def destroy
    menu = Current.business_owner.menus.find(params[:id])
    outcome = ::Menus::Delete.run(menu: menu)

    if outcome.valid?
      redirect_to lines_user_bot_settings_menus_path(business_owner_id), notice: I18n.t("common.delete_successfully_message")
    else
      redirect_to lines_user_bot_settings_menu_path(business_owner_id, menu), flash: { alert: I18n.t("active_interaction.errors.models.menus/delete.attributes.menu.be_used_by_booking_page") }
    end
  end
end
