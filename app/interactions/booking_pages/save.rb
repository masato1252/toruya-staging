module BookingPages
  class Save < ActiveInteraction::Base
    object :booking_page, class: "BookingPage"

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
      hash :special_dates, default: nil, strip: false
    end

    def execute
      booking_options = attrs.delete(:options)
      special_dates = attrs.delete(:special_dates)

      attrs.merge!(booking_option_ids: booking_options&.values&.pluck(:value) )

      booking_page.transaction do
        if booking_page.update(attrs)
          booking_page.booking_page_special_dates.destroy_all
          special_dates.values.each do |date_times|
            booking_page.booking_page_special_dates.create(date_times)
          end
          booking_page
        else
          errors.merge!(booking_page.errors)
        end
      end
    end
  end
end
