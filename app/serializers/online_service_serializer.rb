# frozen_string_literal: true

class OnlineServiceSerializer
  include JSONAPI::Serializer
  attribute :id, :user_id, :name, :note, :content, :solution_type, :upsell_sale_page_id, :end_time, :end_time_text, :start_time, :start_time_text, :content_url, :external_purchase_url, :customer_address_required
  attribute :product_name, &:name

  attribute :internal_name do |service|
    service.internal_name.presence || service.name
  end

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

  attribute :one_time_charge_required do |service|
    service.one_time_charge_required?
  end

  attribute :recurring_charge_required do |service|
    service.recurring_charge_required?
  end

  attribute :bundled_services do |service|
    service.bundled_services.map do |bundled_service|
      BundledServiceSerializer.new(bundled_service).attributes_hash
    end
  end
end
