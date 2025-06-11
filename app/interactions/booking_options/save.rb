# frozen_string_literal: true

module BookingOptions
  class Save < ActiveInteraction::Base
    object :booking_option, class: "BookingOption"

    hash :attrs, default: nil do
      string :name
      string :display_name, default: nil
      integer :minutes
      integer :amount_cents
      boolean :menu_restrict_order, default: false
      boolean :tax_include, default: false
      integer :ticket_quota, default: 1
      integer :ticket_expire_month, default: 1
      string :option_type, default: "primary"
      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil
      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil
      string :memo, default: nil
      # menus hash
      # {
      #   "0" => { "label" => "menu_name", "value" => "menu_id", "priority" => 0, "required_time" => 100 },
      #   "1" => { "label" => "ANAT002筋骨BODY", "value" => "6", "priority" => 1, "required_time" => 200 }
      # }
      hash :menus, default: nil, strip: false
    end

    def execute
      menus = attrs.delete(:menus)

      booking_option.with_lock do
        if booking_option.update(
            attrs.merge!(
              start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil,
              end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil,
              amount_currency: booking_option.user.currency
            ))
          booking_option.booking_option_menus.destroy_all
          booking_option_menus = booking_option.booking_option_menus.create(
            menus&.values&.map do |menu|
              {
                menu_id: menu["value"],
                priority: menu["priority"],
                required_time: menu["required_time"]
              }
            end || []
          )

          if first_invalid_record = booking_option_menus.find { |booking_option_menu| booking_option_menu.invalid? }
            errors.merge!(first_invalid_record.errors)

            raise ActiveRecord::Rollback
          end

          booking_option
        else
          errors.merge!(booking_option.errors)
        end
      end
    end
  end
end