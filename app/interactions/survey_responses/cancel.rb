# frozen_string_literal: true

module SurveyResponses
  class Cancel < ActiveInteraction::Base
    object :survey_response

    def execute
      survey_response.with_lock do
        survey_response.canceled!
        survey_response.reservation_customers.each do |reservation_customer|
          compose(ReservationCustomers::Cancel,
            reservation_id: reservation_customer.reservation_id,
            customer_id: reservation_customer.customer_id)
        end

        Notifiers::Customers::Surveys::ActivityCanceledResponse.perform_later(
          survey_response: survey_response,
          receiver: survey_response.customer
        )
      end
    end
  end
end
