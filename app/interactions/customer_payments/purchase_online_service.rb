# frozen_string_literal: true

class CustomerPayments::PurchaseOnlineService < ActiveInteraction::Base
  object :sale_page
  object :customer

  def execute
    relation = product.online_service_customer_relations
      .find_by(sale_page: sale_page, online_service: product, customer: customer)

    order_id = SecureRandom.hex(8).upcase
    expire_at = product.current_expire_time

    payment = customer.customer_payments.create!(
      product: sale_page,
      rank: charging_rank,
      amount: sale_page.selling_price_amount,
      charge_at: Time.current,
      expire_at: expire_at,
      manual: true,
      order_id: order_id
    )

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

      if Rails.configuration.x.env.production?
        Slack::Web::Client.new.chat_postMessage(channel: 'development', text: "[OK] 🎉Sale Page #{sale_page.id} Stripe charge💰")
      end
    rescue Stripe::CardError => error
      payment.stripe_charge_details = error.json_body[:error]
      errors.add(:customer, :auth_failed)

      Rollbar.error(error, toruya_service_charge: relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue Stripe::StripeError => error
      payment.stripe_charge_details = error.json_body[:error]
      errors.add(:customer, :processor_failed)

      Rollbar.error(error, toruya_service_charge: relation.id, stripe_charge: error.json_body[:error], rails_env: Rails.configuration.x.env)
    rescue => e
      Rollbar.error(e)
      errors.add(:customer, :something_wrong)
    end
  end
end
