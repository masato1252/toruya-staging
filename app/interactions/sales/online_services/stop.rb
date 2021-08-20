# frozen_string_literal: true

module Sales
  module OnlineServices
    class Stop < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_online_service_external

      def execute
        compose(Sales::OnlineServices::Cancel, relation: relation)
      end

      private

      def validate_online_service_external
        unless relation.online_service.external?
          errors.add(:relation, :external_service_required)
        end
      end
    end
  end
end
