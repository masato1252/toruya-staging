# frozen_string_literal: true

class SalePages::BookingPageSerializer < SalePageSerializer
  # TODO: pass params to serializer
  attribute :product do |object, params|
    ::BookingPageSerializer.new(object.product, params: params).attributes_hash.merge!(
      url: Rails.application.routes.url_helpers.booking_page_url(object.product.slug, _from: "sale_page", _from_id: object.id, function_access_id: params[:function_access_id])
    )
  end

  attribute :shop do |object|
    CompanyInfoSerializer.new(object.user.profile).attributes_hash
  end

  attribute :company_info do |object|
    CompanyInfoSerializer.new(object.user.profile).attributes_hash
  end
end
