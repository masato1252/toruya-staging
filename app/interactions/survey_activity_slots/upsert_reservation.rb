module SurveyActivitySlots
  class UpsertReservation < ActiveInteraction::Base
    object :survey, class: Survey
    object :activity, class: SurveyActivity
    object :slot, class: SurveyActivitySlot
    object :customer, class: Customer, default: nil
    object :survey_response, class: SurveyResponse, default: nil

    def execute
      reservation = Reservation.find_by(
        user: user,
        shop: shop,
        survey_activity: activity,
        survey_activity_slot: slot
      )

      ApplicationRecord.transaction do
        if reservation.nil?
          has_accepted_response = activity.survey_responses.any?(&:accepted?)
          reservation_state = has_accepted_response ? ReservationStaff::ACCEPTED_STATE : ReservationStaff::PENDING_STATE

          reservation = Reservation.create!(
            user: user,
            shop: shop,
            start_time: slot.start_time,
            ready_time: slot.start_time,
            end_time: slot.end_time,
            count_of_customers: 0,
            survey_activity: activity,
            survey_activity_slot: slot
          )

          reservation.reservation_staffs.create(
            staff_id: user.current_staff.id,
            state: reservation_state,
            prepare_time: slot.start_time,
            work_start_at: slot.start_time,
            work_end_at: slot.end_time,
            ready_time: slot.start_time
          )
        else
          # Update reservation times and clear deleted_at flag
          reservation.update!(
            start_time: slot.start_time,
            ready_time: slot.start_time,
            end_time: slot.end_time,
            deleted_at: nil
          )

          # If reservation was canceled, set it back to pending state, otherwise keep current state
          if reservation.canceled?
            reservation.pend!
          end

          reservation.reservation_staffs.update!(
            prepare_time: slot.start_time,
            work_start_at: slot.start_time,
            work_end_at: slot.end_time,
            ready_time: slot.start_time
          )
        end

        user.booking_pages.each do |booking_page|
          ::Booking::Cache.perform_later(booking_page: booking_page, date: reservation.start_time.to_date)
        end

        if customer.present?
          if !ReservationCustomer.where(reservation: reservation, customer: customer).exists?
            ReservationCustomer.create!(
              reservation: reservation,
              customer: customer,
              state: survey_response&.state || :pending,
              survey_activity_id: activity.id,
              slug: SecureRandom.alphanumeric(10)
            )
          end

          reservation.update!(count_of_customers: reservation.reservation_customers.active.count)
        end
      end
    end

    private

    def user
      @user ||= survey.user
    end

    def shop
      @shop ||= user.shop
    end
  end
end
