module Broadcasts
  class FilterCustomers < ActiveInteraction::Base
    object :broadcast

    def execute
      customers =
        case broadcast.query_type
        when "manual_assignment"
          return broadcast.user.customers.where(id: broadcast.receiver_ids)
        when "active_customers"
          broadcast.user.customers.active_in(3.months.ago)
        when "online_service_for_active_customers"
          compose(Broadcasts::QueryActiveServiceCustomers, user: broadcast.user, query: broadcast.query)
        when "reservation_customers"
          reservation_id = broadcast.query["filters"][0]["value"]
          Reservation.find(reservation_id).customers
        else
          compose(Broadcasts::QueryCustomers, user: broadcast.user, query: broadcast.query)
        end

      customers.select {|customer| !customer.in_blacklist? }
    end
  end
end
