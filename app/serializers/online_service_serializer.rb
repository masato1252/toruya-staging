# frozen_string_literal: true

class OnlineServiceSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :content, :solution_type, :upsell_sale_page_id, :end_time, :end_time_text, :start_time, :start_time_text
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

  attribute :content_url do |service|
    service.content["url"]
  end
end
