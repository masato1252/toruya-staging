module BookingPages
  class Update < ActiveInteraction::Base
    object :booking_page, class: "BookingPage"
    string :update_attribute

    hash :attrs, default: nil, strip: false do
      string :name, default: nil
      string :title, default: nil
      boolean :draft, default: true
      boolean :line_sharing, default: true
      integer :shop_id, default: nil
      integer :booking_limit_day, default: 1
      string :greeting, default: nil
      string :note, default: nil
      integer :interval, default: 30
      boolean :overbooking_restriction, default: true

      integer :new_option, default: nil

      string :start_at_date_part, default: nil
      string :start_at_time_part, default: nil
      string :end_at_date_part, default: nil
      string :end_at_time_part, default: nil
      # special_dates array
      # [
      #   {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"},
      #   {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"}
      # [
      array :special_dates, default: nil do
        hash do
          string :start_at_date_part
          string :start_at_time_part
          string :end_at_date_part
          string :end_at_time_part
        end
      end
    end

    def execute
      booking_options = attrs.delete(:options)
      new_option = attrs.delete(:new_option)
      special_dates = attrs.delete(:special_dates)

      booking_page.transaction do
        case update_attribute
        when "special_dates"
          booking_page.booking_page_special_dates.destroy_all

          if special_dates
            special_dates.each do |date_times|
              booking_page.booking_page_special_dates.create(date_times)
            end
          end
        when "new_option"
          booking_page.update(booking_option_ids: booking_page.booking_option_ids.push(new_option).uniq )
        when "start_at"
          booking_page.update(start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil)
        when "end_at"
          booking_page.update(end_at: attrs[:end_at_date_part] ? Time.zone.parse("#{attrs[:end_at_date_part]}-#{attrs[:end_at_time_part]}") : nil)
        when "name", "title", "draft", "line_sharing", "shop_id", "booking_limit_day", "greeting", "note", "interval", "overbooking_restriction"
          booking_page.update(attrs.slice(update_attribute))
        end

        if booking_page.errors.present?
          errors.merge!(booking_page.errors)
        end

        booking_page
      end
    end
  end
end
