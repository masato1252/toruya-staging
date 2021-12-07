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
      price_options = {
        price_types: [],
        price_amounts: {}
      }

      if object.selling_price_amount_cents
        price_options[:price_types] << "one_time"
        price_options[:price_amounts].merge!(
          one_time: {
            amount: object.selling_price_amount.fractional,
            amount_format: object.selling_price_amount.format
          }
        )
      end

      if object.selling_multiple_times_price.present?
        price_options[:price_types] << "multiple_times"
        price_options[:price_amounts].merge!(
          multiple_times: {
            times: object.selling_multiple_times_price.size,
            amount: object.selling_multiple_times_price.first,
            amount_format: Money.new(object.selling_multiple_times_price.first).format
          }
        )
      end

      if object.selling_multiple_times_price.blank? && object.selling_multiple_times_price.blank?
        price_options[:price_types] << "free"
      end

      price_options
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
