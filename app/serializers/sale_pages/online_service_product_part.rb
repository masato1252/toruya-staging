# frozen_string_literal: true

module SalePages::OnlineServiceProductPart
  extend ActiveSupport::Concern

  included do
    attribute :product do |sale_page|
      sale_page.product.is_a?(BookingPage) ? ::BookingPageSerializer.new(sale_page.product).attributes_hash : ::OnlineServiceSerializer.new(sale_page.product).attributes_hash
    end

    attribute :introduction_video do |object|
      { url: object.introduction_video_url }
    end

    attribute :price do |object|
      { price_amount: object.selling_price_amount&.format(symbol: false) }
    end

    attribute :normal_price do |object|
      { price_amount: object.normal_price_amount&.format(symbol: false) }
    end
  end
end
