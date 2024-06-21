# frozen_string_literal: true

class OnlineServiceOptionSerializer
  include JSONAPI::Serializer
  attribute :id, :user_id, :name, :note, :content, :solution_type, :upsell_sale_page_id, :end_time, :end_time_text, :start_time, :start_time_text, :content_url, :external_purchase_url
  attribute :product_name, &:name

  attribute :internal_name do |service|
    service.internal_name.presence || service.name
  end

  attribute :solution do |service|
    I18n.t("user_bot.dashboards.online_service_creation.solutions.#{service.solution_type}.title")
  end

  attribute :company_info do |service|
    CompanyInfoSerializer.new(service.company).attributes_hash
  end
end
