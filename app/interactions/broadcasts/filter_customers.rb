module Broadcasts
  class FilterCustomers < ActiveInteraction::Base
    object :broadcast

    def execute
      case broadcast.query_type
      when "online_service_for_active_customers"
        compose(Broadcasts::QueryActiveServiceCustomers, user: broadcast.user, query: broadcast.query)
      when "reservation_customers"
        reservation_id = broadcast.query["filters"][0]["value"]
        Reservation.find(reservation_id).customers.marketable
      else
        compose(Broadcasts::QueryCustomers, user: broadcast.user, query: broadcast.query)
      end
    end
  end
end
