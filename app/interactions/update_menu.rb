class UpdateMenu < ActiveInteraction::Base
  set_callback :type_check, :before do
    attrs.merge!(max_seat_number: nil)  if attrs[:max_seat_number].blank?
    menu_reservation_setting_rule_attributes.merge!(start_date: nil)  if menu_reservation_setting_rule_attributes[:start_date].blank?
  end

  object :menu, class: Menu
  hash :attrs do
    string :name
    string :shortname, default: nil
    integer :minutes, default: nil
    integer :interval, default: nil
    integer :min_staffs_number, default: nil
    integer :max_seat_number, default: nil
    array :shop_ids, default: []
    array :category_ids, default: []
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
    unless menu.save
      errors.merge(menu.errors)
    end


    menu.build_menu_reservation_setting_rule unless menu.menu_reservation_setting_rule
    if (menu_reservation_setting_rule_attributes && menu_reservation_setting_rule_attributes[:start_date]) || !menu.menu_reservation_setting_rule.new_record?
      menu.menu_reservation_setting_rule.update_attributes(menu_reservation_setting_rule_attributes)
    end

    menu.reservation_setting = ReservationSetting.find(reservation_setting_id) if reservation_setting_id
  end
end
