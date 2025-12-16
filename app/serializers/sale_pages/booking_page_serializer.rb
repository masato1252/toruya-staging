# frozen_string_literal: true

class SalePages::BookingPageSerializer < SalePageSerializer
  # TODO: pass params to serializer
  attribute :product do |object, params|
    booking_page_attrs = ::BookingPageSerializer.new(object.product, params: params).attributes_hash
    
    # Override is_started, is_ended, start_time, and end_time to use SalePage's selling period instead of BookingPage's period
    booking_page_attrs.merge!(
      url: Rails.application.routes.url_helpers.booking_page_url(object.product.slug, _from: "sale_page", _from_id: object.id, function_access_id: params[:function_access_id]),
      is_started: object.started?,
      is_ended: object.ended?,
      start_time: object.start_time_text,
      end_time: object.end_time_text
    )
  end

  attribute :shop do |object|
    CompanyInfoSerializer.new(object.user.profile).attributes_hash
  end

  attribute :company_info do |object|
    CompanyInfoSerializer.new(object.user.profile).attributes_hash
  end
end
