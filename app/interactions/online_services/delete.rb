# frozen_string_literal: true

module OnlineServices
  class Delete < ActiveInteraction::Base
    object :online_service

    validate :validate_no_customer_relation

    def execute
      online_service.update(deleted_at: Time.current)
    end

    private

    def validate_no_customer_relation
      errors.add(:online_service, :has_customer_relation) if online_service.available_online_service_customer_relations.exists?
    end
  end
end