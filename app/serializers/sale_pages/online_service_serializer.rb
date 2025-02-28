# frozen_string_literal: true


class SalePages::OnlineServiceSerializer < SalePageSerializer
  include SalePages::OnlineServiceProductPart
  attribute :quantity

  attribute :product do |sale_page|
    ::OnlineServiceSerializer.new(sale_page.product).attributes_hash
  end

  attribute :start_at do |object|
    object.selling_start_at ? I18n.l(object.selling_start_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_now")
  end

  attribute :is_started do |object|
    object.started?
  end

  attribute :is_ended do |sale_page|
    sale_page.ended? || sale_page.sold_out?
  end

  attribute :purchase_url do |object, params|
    Rails.application.routes.url_helpers.new_lines_customers_online_service_purchases_url(slug: object.slug, _from: "sale_page", _from_id: object.id, function_access_id: params[:function_access_id])
  end

  attribute :company_info do |object|
    CompanyInfoSerializer.new(object.user.profile).attributes_hash
  end

  attribute :payable do |object|
    object.payable?
  end

  attribute :recurring_charge_required do |object|
    object.product.recurring_charge_required?
  end
end
