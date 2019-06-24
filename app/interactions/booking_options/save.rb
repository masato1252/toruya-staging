module BookingOptions
  class Save < ActiveInteraction::Base
    object :booking_option, class: "BookingOption"

    hash :attrs, default: nil do
      string :name
      string :display_name, default: nil
      integer :minutes
      integer :interval
      integer :amount_cents
      string :amount_currency, default: "JPY"
      boolean :menu_restrict_order, default: false
      boolean :tax_include, default: false
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
        if booking_option.update(attrs)
          booking_option.booking_option_menus.destroy_all
          booking_option.booking_option_menus.create(
            menus&.values&.map do |menu|
              {
                menu_id: menu["value"],
                priority: menu["priority"],
                required_time: menu["required_time"]
              }
            end || []
          )

          booking_option
        else
          errors.merge!(booking_option.errors)
        end
      end
    end
  end
end
