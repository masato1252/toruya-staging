module Reservable
  class CalculateCapabilityForCustomers < ActiveInteraction::Base
    object :shop
    integer :menu_id
    array :staff_ids

    def execute
      shop_max_seat_number = shop_menu.max_seat_number || 1

      staff_max_customers = StaffMenu.where(staff_id: staff_ids, menu_id: menu_id).where.not(max_customers: nil).minimum(:max_customers) || 0

      [shop_max_seat_number, staff_max_customers].min
    end

    private

    def shop_menu
      @shop_menu ||= shop.shop_menus.find_by!(menu_id: menu_id)
    end
  end
end
