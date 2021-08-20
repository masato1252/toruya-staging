# frozen_string_literal: true

require "line_client"
require "message_encryptor"
require "translator"

module Sales
  module OnlineServices
    class Purchase < ActiveInteraction::Base
      object :sale_page
      object :customer
      string :authorize_token, default: nil

      validate :validate_product
      validate :validate_token

      def execute
        relation =
          begin
            OnlineServiceCustomerRelation.transaction do
              product.online_service_customer_relations
                .create_with(sale_page: sale_page)
                .find_or_create_by(online_service: product, customer: customer)
            end
          rescue ActiveRecord::RecordNotUnique
            retry
          end

        relation.with_lock do
          unless relation.purchased?
            if sale_page.free?
              relation.permission_state = :active
              relation.expire_at = product.current_expire_time
              relation.free_payment_state!

              ::OnlineServices::Attend.run(customer: customer, online_service: product, sale_page: sale_page)
            elsif !sale_page.external?
              compose(Customers::StoreStripeCustomer, customer: customer, authorize_token: authorize_token)
              purchase_outcome = CustomerPayments::PurchaseOnlineService.run(sale_page: sale_page, customer: customer)

              # credit card charge is synchronous request, it would return final status immediately
              if purchase_outcome.valid?
                Sales::OnlineServices::Approve.run(relation: relation, customer: customer, online_service: product)
              else
                relation.failed_payment_state!
              end
            end
          end
        end

        compose(Users::UpdateCustomerLatestActivityAt, user: sale_page.user)

        if relation.purchased?
          ::LineClient.flex(
            social_customer,
            LineMessages::FlexTemplateContainer.template(
              altText: I18n.t("notifier.online_service.purchased.#{sale_page.product.solution_type}.message", service_title: sale_page.product.name),
              contents: compose(Templates::OnlineService, sale_page: sale_page, online_service: sale_page.product, social_customer: social_customer)
            )
          )
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

      def validate_token
        if !sale_page.free? && !sale_page.external? && authorize_token.blank?
          errors.add(:authorize_token, :invalid_token)
        end
      end
    end
  end
end
