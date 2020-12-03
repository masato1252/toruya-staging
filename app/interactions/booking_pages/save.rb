module BookingPages
  class Save < ActiveInteraction::Base
    object :booking_page, class: "BookingPage"

    hash :attrs, default: nil do
      boolean :draft, default: true
      boolean :line_sharing, default: true
      integer :shop_id
      integer :booking_limit_day, default: 1
      string :name
      string :title, default: nil
      string :greeting, default: nil
      string :note, default: nil
      integer :interval, default: 30
      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil
      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil
      # options hash
      # {
      #   "0" => { "label" => "booking_option_name", "value" => "booking_option_id" },
      #   "1" => { "label" => "ANAT002筋骨BODY", "value" => "6" }
      # }
      hash :options, default: nil, strip: false
      # special_dates hash
      # {
      #   "0" => {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"},
      #   "1" = >{"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"}
      # }
      hash :special_dates, default: nil, strip: false
      boolean :overbooking_restriction, default: true
    end

    def execute
      booking_options = attrs.delete(:options)
      special_dates = attrs.delete(:special_dates)

      attrs.merge!(booking_option_ids: booking_options&.values&.pluck(:value) )

      booking_page.transaction do
        if booking_page.update(
            attrs.merge!(
              start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil,
              end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil
            ))
          booking_page.booking_page_special_dates.destroy_all

          if special_dates
            special_dates.values.each do |date_times|
              booking_page.booking_page_special_dates.create(date_times)
            end
          end
          booking_page
        else
          errors.merge!(booking_page.errors)
        end
      end
    end
  end
end
