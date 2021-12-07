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
