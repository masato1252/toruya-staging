class SalePageOptionSerializer
  include JSONAPI::Serializer
  attribute :id

  attribute :label do |sale_page|
    sale_page.product.name
  end

  attribute :start_time do |sale_page|
    booking_page = sale_page.product

    booking_page.start_at ? I18n.l(booking_page.start_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_now")
  end

  attribute :end_time do |sale_page|
    booking_page = sale_page.product

    booking_page.end_at ? I18n.l(booking_page.end_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_forever")
  end

  attribute :product do |sale_page|
    BookingPageSerializer.new(sale_page.product).attributes_hash
  end

  attribute :shop do |sale_page|
    ShopSerializer.new(sale_page.product.shop).attributes_hash
  end

  attribute :template do |sale_page|
    sale_page.sale_template.view_body
  end

  attribute :template_variables do |sale_page|
    sale_page.sale_template_variables
  end

  attribute :social_account_add_friend_url do |sale_page|
    sale_page.product.user.social_accounts.first&.add_friend_url
  end
end
