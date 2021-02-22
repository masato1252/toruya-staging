# frozen_string_literal: true

class BookingPageSalePageSerializer < SalePageSerializer
  attribute :flow

  attribute :product do |object|
    BookingPageSerializer.new(object.product).attributes_hash.merge!(
      url: Rails.application.routes.url_helpers.booking_page_url(object.product.slug, from: "sale_page", from_id: object.id)
    )
  end

  attribute :shop do |object|
    ShopSerializer.new(object.product.shop).attributes_hash
  end
end
