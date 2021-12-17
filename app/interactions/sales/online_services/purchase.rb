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
      string :payment_type

      validate :validate_product
      validates :payment_type, inclusion: { in: SalePage::PAYMENTS.values }

      def execute
        relation = compose(
          ::Sales::OnlineServices::Apply,
          sale_page: sale_page,
          online_service: product,
          customer: customer,
          payment_type: payment_type
        )

        # TODO: need spec
        if !sale_page.free? && !sale_page.external? && !relation.purchased? && authorize_token.blank?
          errors.add(:authorize_token, :invalid_token)
          return
        end

        relation.with_lock do
          if !relation.purchased?
            if relation.inactive?
              relation = compose(
                ::Sales::OnlineServices::Reapply,
                online_service_customer_relation: relation,
                payment_type: payment_type
              )
            end

            if sale_page.free?
              ::Sales::OnlineServices::Approve.run(relation: relation)
            elsif !sale_page.external?
              compose(Customers::StoreStripeCustomer, customer: customer, authorize_token: authorize_token)
              purchase_outcome = CustomerPayments::PurchaseOnlineService.run(
                online_service_customer_relation: relation,
                first_time_charge: true,
                manual: true
              )

              # credit card charge is synchronous request, it would return final status immediately
              if purchase_outcome.valid?
                Sales::OnlineServices::Approve.run(relation: relation)
                Sales::OnlineServices::ScheduleCharges.run(relation: relation)
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
              altText: I18n.t("notifier.online_service.purchased.#{product.solution_type_for_message}.message", service_title: sale_page.product.name),
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
    end
  end
end
