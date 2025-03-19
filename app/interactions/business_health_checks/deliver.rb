# frozen_string_literal: true

module BusinessHealthChecks
  class Deliver < ActiveInteraction::Base
    BOOKING_PAGE_VISIT_CRITERIA = 10
    BOOKING_PAGE_CONVERSION_RATE_CRITERIA = 0.1
    NO_NEW_CUSTOMER_CHECKING_PERIOD = 60
    MESSAGES_FROM_CUSTOMER_CRITERIA = 10
    HEALTH_CHECK_PERIOD = 30
    MESSAGE_FROM_CUSTOMER_CHECKING_PERIOD = 14
    object :subscription

    def execute
      if !any_booking_page_visit_ever_over_criteria
        Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughPageView.run(receiver: user)
      elsif any_booking_page_visit_ever_over_criteria && !any_booking_page_page_view_and_conversion_rate_ever_over_criteria
        Notifiers::Users::BusinessHealthChecks::BookingPageNotEnoughBooking.run(receiver: user)
      elsif !enough_messages_from_customer
        Notifiers::Users::BusinessHealthChecks::NoEnoughMessage.run(receiver: user)
      elsif any_booking_page_visit_ever_over_criteria && any_booking_page_page_view_and_conversion_rate_ever_over_criteria && !any_new_customer_for_a_period
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

    def enough_messages_from_customer
      @enough_messages_from_customer ||= begin
        count = SocialMessage
                .where(social_account_id: user.social_account.id)
                .from_customer
                .where("created_at > ?", MESSAGE_FROM_CUSTOMER_CHECKING_PERIOD.days.ago)
                .count
        count >= MESSAGES_FROM_CUSTOMER_CRITERIA
      end
    end

    def booking_page_visit_scope
      @booking_page_visit_scope ||= Ahoy::Visit.where(owner_id: user.id, product_type: "BookingPage")
    end

    def any_booking_page_visit_ever_over_criteria
      return @any_booking_page_visit_ever_over_criteria if defined?(@any_booking_page_visit_ever_over_criteria)

      @any_booking_page_visit_ever_over_criteria ||= begin
        matched = booking_page_visit_scope
          .where(product_id: user.booking_page_ids)
          .where("started_at > ?", HEALTH_CHECK_PERIOD.days.ago)
          .group(:product_id, :product_type)
          .having("count(product_id) > #{BOOKING_PAGE_VISIT_CRITERIA}").exists?
        user.user_metric.update(any_booking_page_visit_ever_over_criteria: matched)
        matched
      end
    end

    def any_booking_page_page_view_and_conversion_rate_ever_over_criteria
      return @any_booking_page_page_view_and_conversion_rate_ever_over_criteria if defined?(@any_booking_page_page_view_and_conversion_rate_ever_over_criteria)
      # booking_page_id_with_reservations_count order by count
      # {
      #   $booking_page_id => $reservations_count,
      #   3 => 123,
      #   2 => 121,
      #   ...
      # }
      @any_booking_page_page_view_and_conversion_rate_ever_over_criteria ||= begin
        booking_page_id_with_reservations_count = ReservationCustomer.where(reservation_id: reservation_ids)
                                                                   .where(booking_page_id: user.booking_page_ids)
                                                                   .where("created_at > ?", HEALTH_CHECK_PERIOD.days.ago)
                                                                   .group(:booking_page_id)
                                                                   .order(count: :desc)
                                                                   .count
        booking_page_id_with_visits_count = booking_page_visit_scope
                                            .where(product_id: booking_page_id_with_reservations_count.keys)
                                            .where("started_at > ?", HEALTH_CHECK_PERIOD.days.ago)
                                            .group(:product_id)
                                            .count
        booking_page_id_with_reservations_count.each do |booking_page_id, reservations_count|
          booking_page_view = booking_page_id_with_visits_count[booking_page_id].to_f
          next if booking_page_view.zero?

          if (reservations_count / booking_page_view) > BOOKING_PAGE_CONVERSION_RATE_CRITERIA &&
              (booking_page_view > BOOKING_PAGE_VISIT_CRITERIA)
            user.user_metric.update(any_booking_page_page_view_and_conversion_rate_ever_over_criteria: true)
            return true
          end
        end

        false
      end
    end

    def any_new_customer_for_a_period
      SocialCustomer.where(user_id: user.id)
                    .where.not(customer_id: nil)
                    .where("created_at >= ?", NO_NEW_CUSTOMER_CHECKING_PERIOD.days.ago)
                    .exists?
    end
  end
end
