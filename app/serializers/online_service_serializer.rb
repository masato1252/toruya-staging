# frozen_string_literal: true

class OnlineServiceSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :content, :solution_type
  attribute :product_name, &:name

  attribute :company_info do |service|
    CompanyInfoSerializer.new(service.company).attributes_hash
  end

  attribute :upsell_sale_page do |service|
    service.upsell_sale_page_id ? SalePageOptionSerializer.new(service.sale_page).attributes_hash : nil
  end

  attribute :solution do |service|
    I18n.t("user_bot.dashboards.online_service_creation.solutions.#{service.solution_type}.title")
  end

  attribute :start_time_text do |service|
    "購入後すぐ"
  end

  attribute :end_time_text do |service|
    if service.end_on_days
      I18n.t("sales.expire_after_n_days", days: service.end_on_days)
    elsif service.end_at
      I18n.l(service.end_at, format: :date_with_wday)
    else
      I18n.t("sales.never_expire")
    end
  end
end
