module Broadcasts
  class QueryActiveServiceCustomers < ActiveInteraction::Base
    object :user
    hash :query, strip: false

    def execute
      customers = compose(Broadcasts::QueryCustomers, user: user, query: query)
      active_service_customers & customers
    end

    private

    def active_service_customers
      @active_service_customers ||= OnlineService.where(id: service_ids).map do |service|
        service.available_customers
      end.flatten.uniq
    end

    def service_ids
      @service_ids ||= query["filters"].map { |condition| condition["value"] }
    end
  end
end
