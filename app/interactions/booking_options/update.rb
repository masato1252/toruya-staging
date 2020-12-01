module BookingOptions
  class Update < ActiveInteraction::Base
    object :booking_option, class: "BookingOption"
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :display_name, default: nil
      string :memo, default: nil
      boolean :menu_restrict_order, default: false

      integer :amount_cents, default: nil
      string :amount_currency, default: "JPY"
      boolean :tax_include, default: false

      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil

      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil

      # For adding a new menu
      integer :new_menu_id, default: nil
      integer :new_menu_required_time, default: nil

      # For changing menu priority
      array :sorted_menus_ids, default: []

      # For changing menu required_time
      integer :menu_id, default: nil
      integer :menu_required_time, default: nil
    end

    def execute
      booking_option.with_lock do
        case update_attribute
        when "name", "display_name", "menu_restrict_order", "memo"
          booking_option.update(attrs.slice(update_attribute))
        when "new_menu"
          booking_option.booking_option_menus.create(
            menu_id: attrs["new_menu_id"],
            priority: booking_option.booking_option_menus.count,
            required_time: attrs["new_menu_required_time"]
          )
          booking_option.update(minutes: booking_option.booking_option_menus.sum(:required_time))
        when "start_at"
          booking_option.update(start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil)
        when "end_at"
          booking_option.update(end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil)
        when "price"
          booking_option.update(
            amount: Money.new(attrs[:amount_cents], attrs[:amount_currency]),
            tax_include: attrs[:tax_include]
          )
        when "menus_priority"
          attrs["sorted_menus_ids"].each.with_index do |menu_id, index|
            booking_option.booking_option_menus.find_by(menu_id: menu_id).update_columns(priority: index)
          end
        when "menu_required_time"
          booking_option.booking_option_menus.find_by(menu_id: attrs["menu_id"]).update_columns(required_time: attrs["menu_required_time"])
          booking_option.update(minutes: booking_option.booking_option_menus.sum(:required_time))
        end

        if booking_option.errors.present?
          errors.merge!(booking_option.errors)
        end
      end
    end
  end
end
