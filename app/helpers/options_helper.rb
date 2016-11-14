module OptionsHelper
  def default_options(items)
    return unless items
    items.map { |i| { label: i.name, value: i.id } }
  end

  def menu_options(menus)
    return unless menus
    menus.map { |m| { label: m.name, value: m.id, maxSeatNumber: m.max_seat_number } }
  end

  def menu_group_options(category_menus)
    return unless category_menus

    category_menus.map do |category_menu|
      {
        group_label: category_menu[:category].name,
        options: menu_options(category_menu[:menus])
      }
    end
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
    if setting.try(:id)
      h = {
        label: setting.name, value: setting.id, id: setting.id
      }

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
    customers.map do |c|
      React.camelize_props(c.attributes.merge(
        label: c.name,
        value: c.id,
        group_name: c.contact_group.try(:name),
        rank: c.rank,
        birthday: (c.birthday ? { year: c.birthday.year, month: c.birthday.month, day: c.birthday.day } : ""),
        emails: c.emails || [],
        phone_numbers: c.phone_numbers || [],
        addresses: c.addresses,
        other_addresses: c.other_addresses.try(:present?) ? c.other_addresses.to_json : nil,
        primary_email: c.primary_email || {},
        primary_phone: c.primary_phone || {},
        primary_address: c.primary_address.present? ? Hashie::Mash.new(c.primary_address).tap do |address|
           address.value.postcode1 = address.value.postcode ? address.value.postcode.first(3) : ""
           address.value.postcode2 = address.value.postcode ? address.value.postcode[3..-1] : ""
           streets = address.value.street ? address.value.street.split(",") : []
           address.value.street1 = streets.first
           address.value.street2 = streets[1..-1].try(:join, ",")
        end : {},
        display_address: c.display_address
      ))
    end
  end

  def reservation_options(reservations)
    reservations.map do |r|
      React.camelize_props({
        id: r.id,
        year: r.start_time.year,
        date: I18n.l(r.start_time, format: :month_day_wday),
        start_time: I18n.l(r.start_time, format: :hour_minute),
        end_time: I18n.l(r.start_time, format: :hour_minute),
        menu: r.menu.name,
        shop: r.shop.name,
        state: r.aasm_state,
        shop_id: r.shop_id,
        staffs: r.staffs.map(&:name).join(", ")
      })
    end
  end

  def react_attributes(array)
    array.map { |a| React.camelize_props(a.attributes) }
  end
end
