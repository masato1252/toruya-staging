module OptionsHelper
  def menu_options(menus)
    return unless menus
    menus.map { |m| { label: m.name, value: m.id, maxSeatNumber: m.max_seat_number } }
  end

  def shop_options(shops)
    return [] unless shops.present?
    shops.map { |s| React.camelize_props(s.attributes) }
  end

  def reservation_setting_options(reservation_settings, menu)
    reservation_settings.map do |s|
      reservation_setting_option(s, menu)
    end
  end

  def reservation_setting_option(setting, menu)
    h = {
      label: setting.name, value: setting.id, id: setting.id
    }

    if setting.id
      h.merge!(editPath: edit_settings_reservation_setting_path(setting, from_menu: true, menu_id: menu.id))
    end
    h
  end

  def staff_options(staffs, selected_menu)
    return unless staffs && selected_menu
    staffs.map do |s|
       {
          label: s.name, value: s.id.to_s,
          maxCustomers: s.staff_menus.find { |staff_menu| staff_menu.menu_id == selected_menu.id }.max_customers
       }
    end
  end

  def customer_options(customers)
    return [] unless customers.present?
    customers.map { |c| React.camelize_props(c.attributes.merge(label: c.name, value: c.id, level: c.state)) }
  end

  def react_attributes(array)
    array.map { |a| React.camelize_props(a.attributes) }
  end
end
