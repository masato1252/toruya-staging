# frozen_string_literal: true

module SurveyResponses
  class Accept < ActiveInteraction::Base
    object :survey_response

    def execute
      survey_response.with_lock do
        survey_response.accepted!

        survey_response.reservation_customers.each do |reservation_customer|
          compose(ReservationCustomers::Accept,
            current_staff: Current.business_owner.current_staff,
            reservation_id: reservation_customer.reservation_id,
            customer_id: reservation_customer.customer_id)
        end

        Notifiers::Customers::Surveys::ActivityAcceptedResponse.perform_later(
          survey_response: survey_response,
          receiver: survey_response.customer
        )
      end
    end
  end
end
