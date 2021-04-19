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
          product.online_service_customer_relations
          .create_with(sale_page: sale_page)
          .find_or_create_by(online_service: product, customer: customer)

        unless relation.purchased?
          if sale_page.free?
            relation.permission_state = :active
            relation.expire_at = product.current_expire_time
            relation.free_payment_state!
          else
            compose(Customers::StoreStripeCustomer, customer: customer, authorize_token: authorize_token)
            purchase_outcome = CustomerPayments::PurchaseOnlineService.run(sale_page: sale_page, customer: customer)

            # credit card charge is synchronous request, it would return final status immediately
            if purchase_outcome.valid?
              relation.permission_state = :active
              relation.expire_at = purchase_outcome.result.expire_at
              relation.paid_payment_state!
            end
          end
        end

        if relation.purchased?
          custom_message = CustomMessage.where(service: sale_page.product, scenario: CustomMessage::ONLINE_SERVICE_PURCHASED).take
          if custom_message
            custom_message_content = Translator.perform(custom_message.content, { customer_name: customer.name, service_title: sale_page.product.name })
          end

          if relation.payment_state_changed?(from: "pending", to: "free")
            custom_message_content || I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name)
          elsif relation.payment_state_changed?(from: "pending", to: "paid")
            custom_message_content || I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name)
          end

          if message_content
            ::LineClient.send(social_customer, message_content)
          end

          ::LineClient.flex(
            social_customer,
            LineMessages::FlexTemplateContainer.template(
              altText: I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name),
              contents: LineMessages::FlexTemplateContent.content7(
                picture_url: sale_page.product.thumbnail_url || sale_page.introduction_video_url,
                content_url: Rails.application.routes.url_helpers.online_service_url(slug: sale_page.product.slug),
                title1: sale_page.product.name,
                label: I18n.t("common.responsible_by"),
                context: sale_page.staff.name,
                action_templates: [
                  LineActions::Uri.new(
                    label: I18n.t("action.watch"),
                    url: Rails.application.routes.url_helpers.online_service_url(slug: sale_page.product.slug, encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
                    btn: "primary"
                  )
                ].map(&:template)
              )
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
        if !sale_page.free? && authorize_token.blank?
          errors.add(:authorize_token, :invalid_token)
        end
      end
    end
  end
end
