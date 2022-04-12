# frozen_string_literal: true

module SalePages
  class UpdateRecurringPrice < ActiveInteraction::Base
    object :sale_page
    string :interval
    integer :amount

    validates :interval, inclusion: { in: %w[month year] }
    validates :amount, numericality: { greater_than_or_equal_to: 0 }

    def execute
      # monthly_price, yearly_price
      if sale_page.public_send("#{interval}ly_price")&.amount != amount
        all_recurring_prices = sale_page.all_recurring_prices
        all_recurring_prices.each do |price|
          price.active = false if price.interval == interval
        end

        unless amount.zero?
          recurring_price = RecurringPrice.new(
            interval: interval,
            amount: amount,
            stripe_price_id: compose(
              Sales::OnlineServices::CreateStripePrice,
              online_service: sale_page.product,
              interval: interval,
              amount: amount
            ).id,
            active: true
          )

          if recurring_price.invalid?
            errors.merge!(recurring_price.errors)
            return
          end

          all_recurring_prices.push(recurring_price)
        end

        sale_page.update(recurring_prices: all_recurring_prices.map(&:attributes))
      end

      sale_page
    end
  end
end
