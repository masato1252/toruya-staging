# frozen_string_literal: true

class SalePageOptionSerializer
  include JSONAPI::Serializer
  attribute :id, :slug

  attribute :label do |sale_page|
    sale_page.product.name
  end

  attribute :start_time do |sale_page|
    start_at = sale_page.product.is_a?(BookingPage) ? sale_page.product.start_at : sale_page.selling_start_at


    start_at ? I18n.l(start_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_now")
  end

  attribute :end_time do |sale_page|
    end_at = sale_page.product.is_a?(BookingPage) ? sale_page.product.end_at : sale_page.selling_end_at

    end_at ? I18n.l(end_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_forever")
  end

  attribute :end_at do |sale_page|
    end_at = sale_page.product.is_a?(BookingPage) ? sale_page.product.end_at : sale_page.selling_end_at

    end_at ? end_at.iso8601 : nil
  end

  attribute :product do |sale_page|
    sale_page.product.is_a?(BookingPage) ? BookingPageSerializer.new(sale_page.product).attributes_hash : OnlineServiceSerializer.new(sale_page.product).attributes_hash
  end

  attribute :shop do |sale_page|
    sale_page.product.is_a?(BookingPage) ? CompanyInfoSerializer.new(sale_page.product.shop).attributes_hash : CompanyInfoSerializer.new(sale_page.product.company).attributes_hash
  end

  attribute :template do |sale_page|
    sale_page.sale_template.view_body
  end

  attribute :template_variables do |sale_page|
    sale_page.sale_template_variables
  end
end
