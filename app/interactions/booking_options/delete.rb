# frozen_string_literal: true

module BookingOptions
  class Delete < ActiveInteraction::Base
    object :booking_option, class: "BookingOption"

    validate :validate_booking_page_usage

    def execute
      booking_option.update_columns(delete_at: Time.current)
    end

    private

    def validate_booking_page_usage
      if booking_option.booking_pages.normal.active.exists?
        errors.add(:booking_option, :be_used_by_booking_page)
      end
    end
  end
end
