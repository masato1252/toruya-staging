# frozen_string_literal: true


class SalePages::OnlineServiceSerializer < SalePageSerializer
  include SalePages::OnlineServiceProductPart
  attribute :quantity

  attribute :is_started do |object|
    object.selling_start_at.nil? || Time.current > object.selling_start_at
  end

  attribute :is_ended do |object|
    object.selling_end_at && Time.current > object.selling_end_at
  end

  attribute :purchase_url do |object|
    Rails.application.routes.url_helpers.new_lines_customers_online_service_purchases_url(slug: object.slug)
  end
end
