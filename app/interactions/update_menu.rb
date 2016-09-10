class UpdateMenu < ActiveInteraction::Base
  object :menu, class: Menu
  hash :attrs do
    string :name
    string :shortname, default: nil
    integer :minutes, default: nil
    integer :interval, default: nil
    integer :min_staffs_number, default: nil
    integer :max_seat_number, default: nil
    array :shop_ids, default: []
    array :staff_menus_attributes, default: []
  end

  integer :reservation_setting_id, default: nil
  hash :menu_reservation_setting_rule_attributes, default: nil do
    string :reservation_type, default: nil
    date :start_date, default: nil
    date :end_date, default: nil
    integer :repeats, default: nil
  end

  def execute
    menu.attributes = attrs
    menu.menu_reservation_setting_rule ||= menu.build_menu_reservation_setting_rule

    unless menu.save
      errors.merge(menu.errors)
    end
    menu.menu_reservation_setting_rule.update_attributes(menu_reservation_setting_rule_attributes) if menu_reservation_setting_rule_attributes
    menu.reservation_setting = ReservationSetting.find(reservation_setting_id) if reservation_setting_id
  end
end
