class UpdateMenu < ActiveInteraction::Base
  set_callback :type_check, :before do
    attrs.merge!(max_seat_number: nil)  if attrs[:max_seat_number].blank?
    menu_reservation_setting_rule_attributes.merge!(start_date: nil)  if menu_reservation_setting_rule_attributes[:start_date].blank?
    menu_reservation_setting_rule_attributes.merge!(reservation_type: nil)  if menu_reservation_setting_rule_attributes[:reservation_type].blank?
  end

  object :menu, class: Menu
  hash :attrs do
    string :name
    string :short_name, default: nil
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
  array :new_categories, default: []

  def execute
    categories = new_categories.map do |category_name|
      menu.user.categories.create(name: category_name)
    end

    attrs[:category_ids] = (attrs[:category_ids].presence || []).push(*categories.map(&:id)) if categories.present?

    menu.attributes = attrs

    unless menu.save
      errors.merge!(menu.errors)
    end

    menu.build_menu_reservation_setting_rule unless menu.menu_reservation_setting_rule
    if (menu_reservation_setting_rule_attributes && menu_reservation_setting_rule_attributes[:start_date]) || !menu.menu_reservation_setting_rule.new_record?
      menu.menu_reservation_setting_rule.update_attributes(menu_reservation_setting_rule_attributes)
    end

    menu.reservation_setting = ReservationSetting.find(reservation_setting_id) if reservation_setting_id

    if menu.menu_reservation_setting_rule.repeating?
      shop_repeating_dates =  Menus::RetrieveRepeatingDates.run!(reservation_setting_id: menu.reservation_setting.id,
                                                                 shop_ids: menu.shop_ids,
                                                                 repeats: menu.menu_reservation_setting_rule.repeats,
                                                                 start_date: menu.menu_reservation_setting_rule.start_date)
      shop_repeating_dates.each do |shop_repeating_date|
        menu_repeating_date = ShopMenuRepeatingDate.find_or_initialize_by(shop: shop_repeating_date[:shop], menu: menu)
        menu_repeating_date.dates = shop_repeating_date[:dates]
        menu_repeating_date.end_date = shop_repeating_date[:dates].last
        menu_repeating_date.save
      end

      ShopMenuRepeatingDate.where(menu: menu).where.not(shop_id: menu.shop_ids).delete_all
    else
      ShopMenuRepeatingDate.where(menu: menu).delete_all
    end
  end
end
