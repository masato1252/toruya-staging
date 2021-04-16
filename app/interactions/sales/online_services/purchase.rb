# frozen_string_literal: true

require "line_client"
require "message_encryptor"

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

            begin
              stripe_charge = Stripe::Charge.create(
                {
                  amount: sale_page.selling_price_amount.format(symbol: false),
                  currency: Money.default_currency.iso_code,
                  customer: customer.stripe_customer_id,
                  description: sale_page.product_name,
                  statement_descriptor: "Toruya #{sale_page.product_name}",
                  metadata: {
                    relation: relation.id,
                    sale_page: sale_page.id
                  }
                },
                {
                  api_key: sale_page.user.stripe_provider.access_token
                }
              )

              # credit card charge is synchronous request, it would return final status immediately
              relation.stripe_charge_details = stripe_charge.as_json
              relation.permission_state = :active
              relation.expire_at = product.current_expire_time
              relation.paid_payment_state!

              if Rails.configuration.x.env.production?
                Slack::Web::Client.new.chat_postMessage(channel: 'development', text: "[OK] 🎉Sale Page #{sale_page.id} Stripe charge💰")
              end
            rescue Stripe::CardError => error
              relation.stripe_charge_details = error.json_body[:error]
              relation.auth_failed_payment_state!
              errors.add(:customer, :auth_failed)

              Rollbar.error(error, toruya_service_charge: relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
            rescue Stripe::StripeError => error
              relation.stripe_charge_details = error.json_body[:error]
              relation.processor_failed_payment_state!
              errors.add(:customer, :processor_failed)

              Rollbar.error(error, toruya_service_charge: relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
            rescue => e
              Rollbar.error(e)
              errors.add(:customer, :something_wrong)
            end
          end
        end

        # relation.payment_state = :free
        # relation.permission_state = :active
        # relation.expire_at = product.current_expire_time

        if relation.purchased?
          # if relation.changes to free and paid
            # ::LineClient.send(social_customer, I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name))
          # end
 
          # ::LineClient.flex(
          #   social_customer,
          #   LineMessages::FlexTemplateContainer.template(
          #     altText: I18n.t("online_service_purchases.free_service.purchased_notification_message", service_title: sale_page.product.name),
          #     contents: LineMessages::FlexTemplateContent.content7(
          #       picture_url: sale_page.product.thumbnail_url || sale_page.introduction_video_url,
          #       content_url: Rails.application.routes.url_helpers.online_service_url(slug: sale_page.product.slug),
          #       title1: sale_page.product.name,
          #       label: I18n.t("common.responsible_by"),
          #       context: sale_page.staff.name,
          #       action_templates: [
          #         LineActions::Uri.new(
          #           label: I18n.t("action.watch"),
          #           url: Rails.application.routes.url_helpers.online_service_url(slug: sale_page.product.slug, encrypted_social_service_user_id: MessageEncryptor.encrypt(social_customer.social_user_id)),
          #           btn: "primary"
          #         )
          #       ].map(&:template)
          #     )
          #   )
          # )
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
