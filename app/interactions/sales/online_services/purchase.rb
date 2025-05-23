# frozen_string_literal: true

require "message_encryptor"
require "translator"

module Sales
  module OnlineServices
    class Purchase < ActiveInteraction::Base
      object :sale_page
      object :customer
      string :authorize_token, default: nil
      string :payment_type
      string :payment_intent_id, default: nil
      string :stripe_subscription_id, default: nil
      integer :function_access_id, default: nil

      validate :validate_product
      validates :payment_type, inclusion: { in: SalePage::PAYMENTS.values }

      def execute
        ApplicationRecord.transaction do
          relation = if product.bundler?
            compose(Sales::OnlineServices::PurchaseBundlerService, inputs)
          else
            compose(Sales::OnlineServices::PurchaseNormalService, inputs)
          end

          if function_access_id.present?
            function_access = FunctionAccess.find_by(id: function_access_id)
            if function_access && relation.purchased?
              FunctionAccess.track_conversion(
                content: function_access.content,
                source_type: function_access.source_type,
                source_id: function_access.source_id,
                action_type: function_access.action_type,
                revenue_cents: relation.product_amount.fractional,
                label: function_access.label
              )
              relation.update!(function_access_id: function_access_id)
            end
          end

          relation
        end
      end

      private

      def product
        @product ||= sale_page.product
      end

      def social_customer
        @social_customer ||= customer.social_customer
      end

      def validate_product
        if !product.is_a?(OnlineService)
          errors.add(:sale_page, :invalid_product)
        end
      end
    end
  end
end
