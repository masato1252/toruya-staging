# frozen_string_literal: true

require "line_client"
require "message_encryptor"

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
        persisted_record = relation.persisted?

        if relation.save
          unless persisted_record
            ::LineClient.send(social_customer, I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name))
          end

          ::LineClient.flex(
            social_customer,
            LineMessages::FlexTemplateContainer.template(
              altText: I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name),
              contents: LineMessages::FlexTemplateContent.content7(
                picture_url: VideoThumb::get(sale_page.product.content["url"], "medium"),
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
