# frozen_string_literal: true

module SalePages::OnlineServiceProductPart
  extend ActiveSupport::Concern

  included do
    attribute :price

    attribute :paying_amount_format, if: Proc.new { |sale_page, params|
      params[:payment_type].present?
    } do |sale_page, params|
      case params[:payment_type]
      when SalePage::PAYMENTS[:one_time]
        sale_page.selling_price_text
      when SalePage::PAYMENTS[:multiple_times]
        sale_page.selling_multiple_times_first_price_text
      end
    end

    attribute :payment_type do |sale_page, params|
      params[:payment_type]
    end

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
