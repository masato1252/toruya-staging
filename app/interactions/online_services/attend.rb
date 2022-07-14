# frozen_string_literal: true

module OnlineServices
  class Attend < ActiveInteraction::Base
    object :customer
    object :online_service

    def execute
      customer.write_attribute(:online_service_ids, (customer.read_attribute(:online_service_ids).concat([online_service.id.to_s])).uniq)
      customer.save
    end
  end
end
