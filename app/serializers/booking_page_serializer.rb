class BookingPageSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :shop_id

  attribute :url do |booking_page|
     Rails.application.routes.url_helpers.booking_page_url(booking_page)
  end

  attribute :price_number do |booking_page|
    booking_page.booking_options.order(amount_cents: :asc).first.amount.fractional
  end

  attribute :price do |booking_page|
    booking_page.booking_options.order(amount_cents: :asc).first.amount.format(:ja_default_format)
  end

  attribute :start_time do |booking_page|
    booking_page.start_at ? I18n.l(booking_page.start_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_now")
  end

  attribute :end_time do |booking_page|
    booking_page.end_at ? I18n.l(booking_page.end_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_forever")
  end
end
