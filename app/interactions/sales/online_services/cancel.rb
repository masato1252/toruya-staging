# frozen_string_literal: true

module Sales
  module OnlineServices
    class Cancel < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current

      def execute
        if relation.online_service.bundler?
          relation.update(payment_state: :canceled, permission_state: :pending)
          # relation.bundled_service_relations.each do |bundled_service_relation|
          #   # only stop subscription, forever still forever
          #   Sales::OnlineServices::Cancel.run(relation: bundled_service_relation)
          # end
        elsif relation.subscription?
          OnlineServiceCustomerRelations::Cancel.run(relation: relation)
        else
          relation.update(payment_state: :canceled, permission_state: :pending)
        end

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
