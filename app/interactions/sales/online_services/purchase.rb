# frozen_string_literal: true

require "line_client"
require "message_encryptor"
require "translator"

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
          .find_or_initialize_by(
            online_service: product,
            customer: customer)

        relation.payment_state = :free
        relation.permission_state = :active
        relation.expire_at = product.current_expire_time
        persisted_record = relation.persisted?

        if relation.save
          unless persisted_record
            if custom_message = CustomMessage.where(service: sale_page.product, scenario: CustomMessage::ONLINE_SERVICE_PURCHASED).take
              ::LineClient.send(social_customer, Translator.perform(custom_message.content, { customer_name: customer.name, service_title: sale_page.product.name }))
            else
              ::LineClient.send(social_customer, I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name))
            end
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
    end
  end
end
