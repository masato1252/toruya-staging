# frozen_string_literal: true

module SurveyResponses
  class Pend < ActiveInteraction::Base
    object :survey_response

    def execute
      survey_response.with_lock do
        survey_response.pending!

        survey_response.reservation_customers.each do |reservation_customer|
          compose(ReservationCustomers::Pend,
            reservation_id: reservation_customer.reservation_id,
            customer_id: reservation_customer.customer_id)
        end

        Notifiers::Customers::Surveys::ActivityPendingResponse.perform_later(
          survey_response: survey_response,
          receiver: survey_response.customer
        )
      end
    end
  end
end
