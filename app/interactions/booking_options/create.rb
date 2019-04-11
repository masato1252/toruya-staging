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
      date_time :start_at, default: nil
      date_time :end_at, default: nil
      string :memo, default: nil
      array :menu_ids, default: nil
    end

    def execute
      booking_option = user.booking_options.new(attrs || {})

      if booking_option.save
        booking_option
      else
        errors.merge!(booking_option.errors)
      end
    end
  end
end
