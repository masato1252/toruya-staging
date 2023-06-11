# frozen_string_literal: true

class SalePages::BookingPageSerializer < SalePageSerializer
  attribute :product do |object|
    ::BookingPageSerializer.new(object.product).attributes_hash.merge!(
      url: Rails.application.routes.url_helpers.booking_page_url(object.product.slug)
    )
  end

  attribute :shop do |object|
    CompanyInfoSerializer.new(object.product.shop).attributes_hash
  end

  attribute :company_info do |object|
    CompanyInfoSerializer.new(object.product.shop).attributes_hash
  end
end
