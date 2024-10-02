# frozen_string_literal: true

module BookingOptions
  class LineSharingOrder < ActiveInteraction::Base
    object :user
    array :booking_option_ids do
      integer
    end

    def execute
      user.with_lock do
        user.user_setting.update!(line_keyword_booking_option_ids: booking_option_ids)

        booking_option_ids.each do |booking_option_id|
          if !BookingPage.joins(:booking_page_options).where(rich_menu_only: true, deleted_at: nil).where("booking_page_options.booking_option_id": booking_option_id).exists?
            compose(
              ::BookingPages::SmartCreate,
              attrs: {
                super_user_id: user.id,
                shop_id: shop.id,
                booking_option_id: booking_option_id,
                rich_menu_only: true
              }
            )
          end

          compose(BookingOptions::SyncBookingPage, booking_option: BookingOption.find(booking_option_id))
        end
      end
    end

    private

    def shop
      user.shops.first
    end
  end
end
