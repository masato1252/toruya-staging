# frozen_string_literal: true


class SalePages::OnlineServiceSerializer < SalePageSerializer
  include SalePages::OnlineServiceProductPart
  attribute :quantity

  attribute :start_at do |object|
    object.selling_start_at ? I18n.l(object.selling_start_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_now")
  end

  attribute :is_started do |object|
    object.selling_start_at.nil? || Time.current > object.selling_start_at
  end

  attribute :is_ended do |object|
    object.selling_end_at && Time.current > object.selling_end_at
  end

  attribute :purchase_url do |object|
    Rails.application.routes.url_helpers.new_lines_customers_online_service_purchases_url(slug: object.slug)
  end

  attribute :company_info do |object|
    CompanyInfoSerializer.new(object.product.company).attributes_hash
  end

  attribute :payable do |object|
    object.free? || (!object.free? && object.user.stripe_provider&.publishable_key&.present?)
  end
end
