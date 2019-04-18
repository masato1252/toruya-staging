module BookingOptions
  class Create < ActiveInteraction::Base
    object :user

    hash :attrs, default: nil do
      string :name
      string :display_name, default: nil
      integer :minutes
      integer :interval
      integer :amount_cents
      string :amount_currency, default: "JPY"
      boolean :tax_include, default: false
      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil
      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil
      string :memo, default: nil
      # menus hash
      # {
      #   "0" => { "label" => "menu_name", "value" => "menu_id" },
      #   "1" => { "label" => "ANAT002筋骨BODY", "value" => "6" }
      # }
      hash :menus, default: nil, strip: false
    end

    def execute
      menus = attrs.delete(:menus)
      attrs.merge!(menu_ids: menus&.values&.pluck(:value) )

      booking_option = user.booking_options.new(attrs || {})

      if booking_option.save
        booking_option
      else
        errors.merge!(booking_option.errors)
      end
    end
  end
end
