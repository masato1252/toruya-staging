# frozen_string_literal: true

# User cancel customers manually
module Sales
  module OnlineServices
    class Cancel < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current

      def execute
        if relation.assignment?
          relation.update(payment_state: :canceled, permission_state: :pending)
        elsif relation.subscription? # subscription might bundler, as well
          OnlineServiceCustomerRelations::Cancel.run(relation: relation)
        elsif relation.online_service.bundler?
          relation.bundled_service_relations.each do |bundled_service_relation|
            OnlineServiceCustomerRelations::ReconnectBestContract.run(relation: bundled_service_relation)
          end
          relation.update(payment_state: :canceled, permission_state: :pending)
        else
          OnlineServiceCustomerRelations::ReconnectBestContract.run(relation: relation)
          relation.canceled_payment_state!
        end

        CustomerPayments::Cancel.run(online_service_customer_relation: relation)

        relation
      end

      private

      def validate_relation_current
        unless relation.current
          errors.add(:relation, :current_true_is_required)
        end
      end
    end
  end
end
