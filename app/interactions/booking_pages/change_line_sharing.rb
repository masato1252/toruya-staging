# frozen_string_literal: true

module BookingPages
  class ChangeLineSharing < ActiveInteraction::Base
    object :booking_page

    def execute
      if booking_page.line_sharing
        user.line_keyword_booking_page_ids.unshift(booking_page.id.to_s)
      else
        user.line_keyword_booking_page_ids.delete(booking_page.id.to_s)
      end

      user.user_setting.update(line_keyword_booking_page_ids: user.line_keyword_booking_page_ids.uniq)
    end

    private

    def user
      @user ||= booking_page.user
    end
  end
end
