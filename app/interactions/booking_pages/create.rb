module BookingPages
  class Create < ActiveInteraction::Base
    object :user

    hash :attrs, default: nil do
      integer :shop_id
      string :name
      string :title, default: nil
      string :greeting, default: nil
      string :note, default: nil
      integer :interval, default: 30
      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil
      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil
      # menus hash
      # {
      #   "0" => { "label" => "booking_option_name", "value" => "booking_option_id" },
      #   "1" => { "label" => "ANAT002筋骨BODY", "value" => "6" }
      # }
      hash :options, default: nil, strip: false
    end

    def execute
      booking_options = attrs.delete(:options)
      attrs.merge!(booking_option_ids: booking_options&.values&.pluck(:value) )

      booking_page = user.booking_pages.new(attrs || {})

      if booking_page.save
        booking_page
      else
        errors.merge!(booking_page.errors)
      end
    end
  end
end
