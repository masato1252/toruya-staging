# frozen_string_literal: true

require "line_client"

module Sales
  module OnlineServices
    class Purchase < ActiveInteraction::Base
      object :sale_page
      object :customer

      validate :validate_product

      def execute
        relation =
          product.online_service_customer_relations
          .create_with(sale_page: sale_page)
          .find_or_create_by(
            online_service: product,
            customer: customer)

        relation.payment_state = :free
        relation.permission_state = :active
        relation.save

        ::LineClient.send(customer.social_customer, Rails.application.routes.url_helpers.online_service_url(slug: sale_page.product.slug))
      end

      private

      def product
        @product ||= sale_page.product
      end

      def validate_product
        if !product.is_a?(OnlineService)
          errors.add(:sale_page, :invalid_product)
        end
      end
    end
  end
end
