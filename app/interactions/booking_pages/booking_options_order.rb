# frozen_string_literal: true

module BookingPages
  class BookingOptionsOrder < ActiveInteraction::Base
    object :booking_page
    array :booking_option_ids do
      integer
    end

    def execute
      booking_page.with_lock do
        booking_page_options = booking_page.booking_page_options.to_a

        booking_option_ids.each.with_index do |booking_option_id, index|
          booking_page_options.find { |booking_page_option| booking_page_option.booking_option_id == booking_option_id }.update_columns(position: index)
        end
      end
    end
  end
end
