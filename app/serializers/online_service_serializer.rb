# frozen_string_literal: true

class OnlineServiceSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :content, :solution_type, :upsell_sale_page_id, :end_time, :end_time_text, :start_time, :start_time_text, :content_url
  attribute :product_name, &:name

  attribute :company_info do |service|
    CompanyInfoSerializer.new(service.company).attributes_hash
  end

  attribute :upsell_sale_page do |service, params|
    if params[:from_upsell]
      nil
    else
      service.upsell_sale_page_id ? SalePageOptionSerializer.new(service.sale_page, params: { from_upsell: true }).attributes_hash : nil
    end
  end

  attribute :solution do |service|
    I18n.t("user_bot.dashboards.online_service_creation.solutions.#{service.solution_type}.title")
  end

  attribute :charge_required do |service|
    service.charge_required?
  end

  attribute :introduction_video_required do |service|
    service.introduction_video_required?
  end
end
