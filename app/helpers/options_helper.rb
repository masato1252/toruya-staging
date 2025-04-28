# frozen_string_literal: true

module OptionsHelper
  def custom_option(item)
    item.attributes.merge({
      label: item.name,
      value: item.id,
    })
  end

  def custom_options(items)
    return [] unless items

    items.map do |item|
      custom_option(item)
    end
  end

  def default_options(items)
    return unless items
    items.map { |i| { label: i.name, value: i.id } }
  end

  def menu_options(menus, attrs = [])
    return unless menus
    menus.map { |m| menu_option(m, attrs) }
  end

  def menu_option(menu, attrs = [])
    return unless menu
    { label: menu.name, value: menu.id, availableSeat: menu.available_seat, required_time: menu.minutes, online: menu.online }.reverse_merge!(menu.attributes.with_indifferent_access.slice(*attrs))
  end

  def rank_options
    Current.business_owner.ranks.order("id DESC").map { |r| { label: r.name, value: r.id, key: r.key } }
  end

  def menu_group_options(category_menus, *attrs)
    return unless category_menus

    if category_menus.first && !category_menus.first.is_a?(Options::MenuOption)
      # When it indeed is category of menus
      category_menus.map do |category_menu|
        {
          label: category_menu[:category].name,
          options: menu_options(category_menu[:menu_options], attrs)
        }
      end
    else
      # When some menu doesn't have category
      menu_options(category_menus, attrs)
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
    shops.map do |s|
      { label: s.name, value: s.id.to_s }
    end
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

      h.merge!(editPath: edit_settings_user_reservation_setting_path(Current.business_owner, setting, from_menu: true, menu_id: menu.id))
    end
    h
  end

  def customer_options(customers, details_permission_checking_required = false)
    return [] unless customers.present?
    customers.map do |c|
      Rails.cache.fetch(c) do
        React.camelize_props(c.attributes.merge(
          label: c.name,
          value: c.id,
          group_name: c.contact_group.try(:name),
          updated_by_user_name: c.updated_by_user.try(:name) || "",
          last_updated_at: c.updated_at ? I18n.l(c.updated_at.to_date, format: :year_month_date) : "",
          rank: c.rank,
          birthday: from_line_bot ? c.birthday : (c.birthday ? { year: c.birthday.year, month: c.birthday.month, day: c.birthday.day } : ""),
          emails: c.emails || [],
          emails_original: c.emails || [],
          phone_numbers: c.phone_numbers || [],
          phone_numbers_original: c.phone_numbers || [],
          addresses: c.addresses,
          other_addresses: c.other_addresses.try(:present?) ? c.other_addresses.to_json : nil,
          primary_email: c.primary_email || {},
          primary_phone: c.primary_phone || {},
          primary_address: c.primary_address.present? ? c.primary_formatted_address : {},
          primary_email_details: c.emails_details&.first || {},
          primary_phone_details: c.phone_numbers_details&.first || {},
          display_address: c.display_address,
          google_down: c.google_down,
          googleContactMissing: c.google_contact_missing,
          details_readable: details_permission_checking_required && can?(:read_details, c),
          social_user_id: c.social_customer&.social_user_id,
          simple_address: c.simple_address
        ))
      end
    end
  end

  def reservation_customer_options(reservation_customers)
    reservation_customers.map do |reservation_customer|
      next unless reservation_customer.reservation

      reservation_option(reservation_customer.reservation).merge!(
        reservation_customer_state: reservation_customer.reservation_state,
        tickets: reservation_customer.customer_tickets.map do |customer_ticket|
          {
            nth_quota: reservation_customer.nth_quota_of_customer_ticket(customer_ticket),
            total_quota: customer_ticket.total_quota,
            ticket_code: customer_ticket.code,
            ticket_expire_date: I18n.l(customer_ticket.expire_at.to_date)
          }
        end
      )
    end.compact
  end

  def reservation_option(r)
    sentences = reservation_staff_sentences(r)

    customer_names = r.customers.map(&:name)
    customer_names_sentence = if customer_names.count > 1
                                "#{customer_names.first} +#{customer_names.count - 1}"
                              else
                                customer_names.first
                              end

    acceptable = r.acceptable_by_staff?(current_staff_of_owner(r.shop.user))

    React.camelize_props({
      type: 'Reservation',
      user_id: r.user_id,
      id: r.id,
      year: r.start_time.year,
      date: r.start_time.to_fs(:date),
      month_date: I18n.l(r.start_time, format: :month_day_wday),
      start_time: I18n.l(r.start_time, format: :hour_minute),
      end_time: I18n.l(r.end_time, format: :hour_minute),
      menu: r.menus.map(&:display_name).join(", ").presence || (r.survey_activity ? r.survey_activity.name : nil),
      shop: r.shop.display_name,
      state: r.aasm_state,
      shop_id: r.shop_id,
      customers: r.customers.map { |c| { id: c.id, name: c.name, user_id: c.user_id } },
      customers_sentence: customer_names_sentence,
      staffs: sentences[:staffs_sentence],
      deleted_staffs: sentences[:deleted_staffs_sentence] ? I18n.t("reservation.deleted_staffs_sentence", staff_names_sentence: sentences[:deleted_staffs_sentence]) : nil,
      memo: simple_format(r.memo),
      with_warnings: r.with_warnings,
      acceptable: acceptable,
      time: r.start_time.to_i
    })
  end

  def reservation_options(reservations)
    reservations.map do |r|
      reservation_option(r)
    end
  end

  def react_attribute(attributes)
    React.camelize_props(attributes)
  end

  def react_attributes(array)
    array.map { |a| react_attribute(a.attributes) }
  end

  def contact_group_options
    default_options(current_user_staff.readable_contact_groups.connected)
  end

  def filtered_outcome_options(filtered_outcomes)
    filtered_outcomes.map{ |outcome|
      React.camelize_props({
        id: outcome.id,
        name: outcome.name,
        file_url: outcome.file.url,
        state: outcome.aasm_state,
        type: I18n.t("customer.filter.printing_types.#{outcome.outcome_type}"),
        created_date: outcome.created_at.to_fs(:date),
        expired_date: outcome.created_at.advance(days: FilteredOutcome::EXPIRED_DAYS).to_fs(:date)
      })
    }
  end

  def regions
    JpPrefecture::Prefecture.all.map {|j| { label: j.name, value: j.name } }
  end

  def year_options
    (1916..Date.current.year).to_a.map {|year| { label: year, value: year }}
  end

  def month_options
    (1..12).to_a.map {|year| { label: year, value: year }}
  end

  def day_options
    (1..31).to_a.map {|year| { label: year, value: year }}
  end

  def rich_menu_layout_option_image_path(index)
    "https://toruya.s3.ap-southeast-1.amazonaws.com/public/rich_menu_layouts/richmenu_layout_#{index}.png"
  end

  def payment_provider_label(provider_name)
    case provider_name
    when AccessProvider.providers[:stripe_connect]
      "Stripe"
    when AccessProvider.providers[:square]
      "Square"
    end
  end
end
