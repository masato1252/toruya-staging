module BookingOptions
  class Update < ActiveInteraction::Base
    object :booking_option, class: "BookingOption"

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
      array :menu_ids, default: nil
    end

    def execute
      if booking_option.update(attrs)
        booking_option
      else
        errors.merge!(booking_option.errors)
      end
    end
  end
end
