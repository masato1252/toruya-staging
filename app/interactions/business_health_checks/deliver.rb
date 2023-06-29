# frozen_string_literal: true

module BusinessHealthChecks
  class Deliver < ActiveInteraction::Base
    BOOKING_PAGE_VISIT_CRITERIA = 10
    BOOKING_PAGE_CONVERSION_RATE_CRITERIA = 0.1
    NO_NEW_CUSTOMER_CHECKING_PERIOD = 60
    object :subscription

    def execute
      if enough_sale_and_booking_page && !any_booking_page_visit_ever_over_criteria
        Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView.run(receiver: user)
      elsif enough_sale_and_booking_page && any_booking_page_visit_ever_over_criteria && !any_booking_page_page_view_and_conversion_rate_ever_over_criteria
        Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking.run(receiver: user)
      elsif enough_sale_and_booking_page && any_booking_page_visit_ever_over_criteria && any_booking_page_page_view_and_conversion_rate_ever_over_criteria && !any_new_customer_for_a_period
        Notifiers::Users::BusinessHealthChecks::NoNewCustomer.run(receiver: user)
      end
    end

    private

    def user
      @user ||= subscription.user
    end

    def reservation_ids
      @reservation_ids ||= user.reservations.pluck(:id)
    end

    def enough_sale_and_booking_page
      @enough_sale_and_booking_page ||= user.sale_pages.exists? && user.booking_pages.active.where("created_at < ?", 30.days.ago).exists?
    end

    def booking_page_visit_scope
      @booking_page_visit_scope ||= Ahoy::Visit.where(owner_id: user.id, product_type: "BookingPage")
    end

    def any_booking_page_visit_ever_over_criteria
      @any_booking_page_visit_ever_over_criteria ||=
        user.user_metric.any_booking_page_visit_ever_over_criteria || begin
      matched = Ahoy::Visit.select(:product_id, :product_type).where(owner_id: user.id, product_type: "BookingPage").where(product_id: user.booking_page_ids).group(:product_id, :product_type).having("count(product_id) > #{BOOKING_PAGE_VISIT_CRITERIA}").exists?
      user.user_metric.update(any_booking_page_visit_ever_over_criteria: matched) if matched
      matched
        end
    end

    def any_booking_page_page_view_and_conversion_rate_ever_over_criteria
      # booking_page_id_with_reservations_count order by count
      # {
      #   $booking_page_id => $reservations_count,
      #   3 => 123,
      #   2 => 121,
      #   ...
      # }
      @any_booking_page_page_view_and_conversion_rate_ever_over_criteria ||=
        user.user_metric.any_booking_page_page_view_and_conversion_rate_ever_over_criteria || begin
      booking_page_id_with_reservations_count = ReservationCustomer.where(reservation_id: reservation_ids).where(booking_page_id: user.booking_page_ids).group(:booking_page_id).order(count: :desc).count
      booking_page_id_with_visits_count = booking_page_visit_scope.where(product_id: booking_page_id_with_reservations_count.keys).group(:product_id).count
      booking_page_id_with_reservations_count.each do |booking_page_id, reservations_count|
        booking_page_view = booking_page_id_with_visits_count[booking_page_id].to_f
        next if booking_page_view.zero?

        if (reservations_count / booking_page_view) > BOOKING_PAGE_CONVERSION_RATE_CRITERIA &&
            (booking_page_view > BOOKING_PAGE_VISIT_CRITERIA)
          user.user_metric.update(any_booking_page_page_view_and_conversion_rate_ever_over_criteria: true)
          return true
        end
      end

      return false
        end
    end

    def any_new_customer_for_a_period
      SocialCustomer.where(user_id: user.id).where.not(customer_id: nil).where(created_at: NO_NEW_CUSTOMER_CHECKING_PERIOD.days.ago..).exists?
    end
  end
end
