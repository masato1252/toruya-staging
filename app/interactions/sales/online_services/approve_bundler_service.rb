# frozen_string_literal: true

module Sales
  module OnlineServices
    class ApproveBundlerService < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      validate :validate_relation_current
      validate :validate_service

      def execute
        relation.permission_state = :active
        #relation.expire_at = relation.online_service.current_expire_time

        # paid_at => bought at, when customer bought this product, it should equals first time pay.
        relation.paid_at = Time.current
        relation.expire_at = nil
        # bundler_relation expire_at is always nil
        relation.save

        relation.online_service.bundled_services.each do |bundled_service|
          compose(Sales::OnlineServices::ApproveBundledService, bundled_service: bundled_service, bundler_relation: relation)
        end

        relation
      end

      private

      def validate_relation_current
        unless relation.current
          errors.add(:relation, :current_true_is_required)
        end
      end

      def validate_service
        unless relation.online_service.bundler?
          errors.add(:relation, :invalid_product)
        end
      end
    end
  end
end
