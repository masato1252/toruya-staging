# frozen_string_literal: true

class Lines::UserBot::BookingPageSpecialDatesController < Lines::UserBotDashboardController
  # show action for dynamic modal loading
  def show
    booking_page_special_date = BookingPageSpecialDate.includes(booking_page: :shop).find(params[:id])

    # Check permission - user must be the owner of the shop
    if booking_page_special_date.booking_page.shop.user_id == Current.business_owner.id
      render partial: 'special_date_modal', locals: {
        booking_page_id: booking_page_special_date.booking_page_id,
        start_time_date_part: booking_page_special_date.start_at_date,
        start_time_time_part: booking_page_special_date.start_at_time,
        end_time_time_part: booking_page_special_date.end_at_time,
        reason: booking_page_special_date.booking_page.title
      }
    else
      head :unprocessable_entity
    end
  end
end