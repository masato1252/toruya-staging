# frozen_string_literal: true

module OnlineServices
  class Attend < ActiveInteraction::Base
    object :customer
    object :online_service
    object :sale_page

    def execute
      customer.write_attribute(:online_service_ids, (customer.read_attribute(:online_service_ids).concat([online_service.id.to_s])).uniq)
      customer.save

      Notifiers::OnlineServices::Purchased.run(receiver: customer, sale_page: sale_page)
    end
  end
end
