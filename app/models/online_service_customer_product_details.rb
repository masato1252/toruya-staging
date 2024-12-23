# frozen_string_literal: true

# product_details: {
#   prices: [
#     {
#       amount: 1000,
#       charge_date: Time.current.to_s, => scheduled job date
#       order_id: XXXX => used by customer_payment order_id
#     },
#     ...
#   ]
# }
require "order_id"

class OnlineServiceCustomerProductDetails
  def self.build(sale_page:, payment_type:)
    prices =
      case payment_type
      when SalePage::PAYMENTS[:one_time]
        [
          OnlineServiceCustomerPrice.new(
            amount: sale_page.selling_price_amount.fractional,
            currency: sale_page.user.currency,
            charge_at: Time.current,
            order_id: OrderId.generate
          ).attributes
        ]
      when SalePage::PAYMENTS[:multiple_times]
        current = Time.current

        sale_page.selling_multiple_times_price.map.with_index do |price, index|
          OnlineServiceCustomerPrice.new(
            amount: price,
            currency: sale_page.user.currency,
            charge_at: current.advance(months: index),
            order_id: OrderId.generate
          ).attributes
        end
      when SalePage::PAYMENTS[:month], SalePage::PAYMENTS[:year]
        recurring_price = sale_page.recurring_prices.find {|price| price[:interval] == payment_type && price[:active] }

        [
          OnlineServiceCustomerPrice.new(
            amount: recurring_price[:amount],
            currency: sale_page.user.currency,
            order_id: OrderId.generate,
            stripe_price_id: recurring_price[:stripe_price_id],
            interval: payment_type
          ).attributes
        ]
      when SalePage::PAYMENTS[:free]
        [
          OnlineServiceCustomerPrice.new(
            amount: 0,
            currency: sale_page.user.currency,
            charge_at: Time.current
          ).attributes
        ]
      when SalePage::PAYMENTS[:bundler]
        [
          OnlineServiceCustomerPrice.new(
            bundler_price: true
          ).attributes
        ]
      end

    {
      prices: prices
    }
  end
end
