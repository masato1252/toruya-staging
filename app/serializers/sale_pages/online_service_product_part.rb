# frozen_string_literal: true

module SalePages::OnlineServiceProductPart
  extend ActiveSupport::Concern

  included do
    attribute :price

    attribute :is_free do |sale_page|
      sale_page.free?
    end

    attribute :is_external do |sale_page|
      sale_page.external?
    end

    attribute :selling_price_option do |object|
      if object.selling_price_amount_cents
        {
          price_type: "one_time",
          price_amount: object.selling_price_amount.fractional,
          price_amount_format: object.selling_price_amount.format
        }
      else
        {
          price_type: "free"
        }
      end
    end

    attribute :quantity_option do |object|
      if object.quantity
        {
          quantity_type: "limited",
          quantity_value: object.quantity
        }
      else
        {
          quantity_type: "unlimited"
        }
      end
    end
  end
end
