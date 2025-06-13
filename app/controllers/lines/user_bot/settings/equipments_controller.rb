# frozen_string_literal: true

class Lines::UserBot::Settings::EquipmentsController < Lines::UserBotDashboardController
  before_action :set_shop
  before_action :set_equipment, only: [:show, :edit, :update, :destroy]

  def index
    @equipments = @shop.active_equipments.order(:name)
  end

  def show
  end

  def new
    @equipment = @shop.equipments.build
    @equipment_menus_options = prepare_equipment_menus_options
  end

  def create
    permitted = params.permit!.to_h
    outcome = Equipments::Upsert.run(
      shop: @shop,
      name: permitted.dig("equipment", "name"),
      quantity: permitted.dig("equipment", "quantity"),
      equipment_menus: permitted["equipment_menus"]
    )

    flash[:notice] = t("common.create_successfully_message") if outcome.valid?
    return_json_response(outcome, { redirect_to: lines_user_bot_settings_shop_equipments_path(business_owner_id: business_owner_id, shop_id: @shop.id) })
  end

  def edit
    @equipment_menus_options = prepare_equipment_menus_options(@equipment)
  end

  def update
    permitted = params.permit!.to_h
    outcome = Equipments::Upsert.run(
      shop: @shop,
      equipment: @equipment,
      name: permitted.dig("equipment", "name"),
      quantity: permitted.dig("equipment", "quantity"),
      equipment_menus: permitted["equipment_menus"]
    )

    flash[:notice] = t("common.update_successfully_message") if outcome.valid?
    return_json_response(outcome, { redirect_to: lines_user_bot_settings_shop_equipments_path(business_owner_id: business_owner_id, shop_id: @shop.id) })
  end

  def destroy
    @equipment.update(deleted_at: Time.current)
    redirect_to lines_user_bot_settings_shop_equipments_path(business_owner_id: business_owner_id, shop_id: @shop.id),
                notice: t("common.delete_successfully_message")
  end

  private

  def set_shop
    @shop = Current.business_owner.shops.find(params[:shop_id])
  end

  def set_equipment
    @equipment = @shop.equipments.find(params[:id])
  end

  def prepare_equipment_menus_options(equipment = nil)
    menus = @shop.menus.includes(:menu_equipments)
    existing_menu_equipments = equipment&.menu_equipments&.index_by(&:menu_id) || {}

    menus.map do |menu|
      existing_relation = existing_menu_equipments[menu.id]
      {
        menu_id: menu.id,
        name: menu.name,
        checked: existing_relation.present?,
        required_quantity: existing_relation&.required_quantity || 1
      }
    end
  end
end