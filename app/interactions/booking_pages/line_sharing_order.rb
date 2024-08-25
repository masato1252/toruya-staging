# frozen_string_literal: true

module BookingPages
  class LineSharingOrder < ActiveInteraction::Base
    object :user
    array :booking_page_ids, default: [] do
      integer
    end

    def execute
      user.with_lock do
        user.user_setting.update!(line_keyword_booking_page_ids: booking_page_ids)
        user.booking_pages.where.not(id: booking_page_ids).update_all(line_sharing: false)
        user.booking_pages.where(id: booking_page_ids).update_all(line_sharing: true)
      end
    end
  end
end
