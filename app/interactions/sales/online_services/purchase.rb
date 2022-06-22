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

      validate :validate_product
      validates :payment_type, inclusion: { in: SalePage::PAYMENTS.values }

      def execute
        if product.bundler?
          compose(Sales::OnlineServices::PurchaseBundlerService, inputs)
        else
          compose(Sales::OnlineServices::PurchaseNormalService, inputs)
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
