class SalePageOptionSerializer
  include JSONAPI::Serializer
  attribute :id

  attribute :label do |sale_page|
    sale_page.product.name
  end

  attribute :type do |sale_page|
    "???"
  end

  attribute :start_time do |sale_page|
    booking_page = sale_page.product

    booking_page.start_at ? I18n.l(booking_page.start_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_now")
  end

  attribute :end_time do |sale_page|
    booking_page = sale_page.product

    booking_page.end_at ? I18n.l(booking_page.end_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_forever")
  end
end
