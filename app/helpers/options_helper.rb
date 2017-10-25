module OptionsHelper
  def default_options(items)
    return unless items
    items.map { |i| { label: i.name, value: i.id } }
  end

  def menu_options(menus)
    return unless menus
    menus.map { |m| { label: m.name, value: m.id, availableSeat: m.available_seat } }
  end

  def rank_options(ranks)
    return unless ranks
    ranks.map { |r| { label: r.name, value: r.id, key: r.key } }
  end

  def menu_group_options(category_menus)
    return unless category_menus

    if category_menus.first && !category_menus.first.is_a?(Options::MenuOption)
      # When it indeed is category of menus
      category_menus.map do |category_menu|
        {
          group_label: category_menu[:category].name,
          options: menu_options(category_menu[:menu_options])
        }
      end
    else
      # When some menu doesn't have category
      menu_options(category_menus)
    end
  end

  def staff_options(staff_options, selected_menu_option)
    return unless staff_options && selected_menu_option
    staff_options.map do |s|
      { label: s.name, value: s.id.to_s, handableCustomers: s.handable_customers }
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

      h.merge!(editPath: edit_settings_user_reservation_setting_path(super_user, setting, from_menu: true, menu_id: menu.id))
    end
    h
  end

  def staff_attributes_options(staffs)
    return [] unless staffs.present?

    staffs.map do |s|
      React.camelize_props(s.attributes.merge(name: s.name))
    end
  end

  def customer_options(customers)
    return [] unless customers.present?
    customers.map do |c|
      React.camelize_props(c.attributes.merge(
        label: c.name,
        value: c.id,
        group_name: c.contact_group.try(:name),
        updated_by_user_name: c.updated_by_user.try(:name) || "",
        last_updated_at: c.updated_at ? I18n.l(c.updated_at.to_date, format: :year_month_date) : "",
        rank: c.rank,
        birthday: (c.birthday ? { year: c.birthday.year, month: c.birthday.month, day: c.birthday.day } : ""),
        emails: c.emails || [],
        emails_original: c.emails || [],
        phone_numbers: c.phone_numbers || [],
        phone_numbers_original: c.phone_numbers || [],
        addresses: c.addresses,
        other_addresses: c.other_addresses.try(:present?) ? c.other_addresses.to_json : nil,
        primary_email: c.primary_email || {},
        primary_phone: c.primary_phone || {},
        primary_address: c.primary_address.present? ? c.primary_formatted_address : {},
        display_address: c.display_address
      ))
    end
  end

  def reservation_options(reservations)
    reservations.map do |r|
      sentences = reservation_staff_sentences(r)

      React.camelize_props({
        id: r.id,
        year: r.start_time.year,
        date: r.start_time.to_s(:date),
        month_date: I18n.l(r.start_time, format: :month_day_wday),
        start_time: I18n.l(r.start_time, format: :hour_minute),
        end_time: I18n.l(r.end_time, format: :hour_minute),
        menu: r.menu.display_name,
        shop: r.shop.display_name,
        state: r.aasm_state,
        shop_id: r.shop_id,
        customers: r.customers.map { |r| { id: r.id, name: r.name } },
        staffs: sentences[:staffs_sentence],
        deleted_staffs: sentences[:deleted_staffs_sentence] ? I18n.t("reservation.deleted_staffs_sentence", staff_names_sentence: sentences[:deleted_staffs_sentence]) : nil,
        memo: simple_format(r.memo),
        with_warnings: r.with_warnings
      })
    end
  end

  def react_attributes(array)
    array.map { |a| React.camelize_props(a.attributes) }
  end

  def contact_group_options
    default_options(super_user.contact_groups.connected)
  end

  def filtered_outcome_options(filtered_outcomes)
    filtered_outcomes.map{ |outcome|
      React.camelize_props({
        id: outcome.id,
        name: outcome&.filter&.name,
        file_url: outcome.file.url,
        state: outcome.aasm_state,
        type: outcome.outcome_type,
        created_date: outcome.created_at.to_s(:date),
        expired_date: outcome.created_at.advance(days: FilteredOutcome::EXPIRED_DAYS).to_s(:date)
      })
    }
  end

  def regions
    JpPrefecture::Prefecture.all.map {|j| { label: j.name, value: j.name } }
  end

  def year_options
    (1916..Date.today.year).to_a.map {|year| { label: year, value: year }}
  end

  def month_options
    (1..12).to_a.map {|year| { label: year, value: year }}
  end

  def day_options
    (1..31).to_a.map {|year| { label: year, value: year }}
  end
end
