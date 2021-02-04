# frozen_string_literal: true

class SalePageSerializer
  include JSONAPI::Serializer
  attribute :flow

  attribute :product do |sale_page|
    BookingPageSerializer.new(sale_page.product).attributes_hash.merge!(
      url: Rails.application.routes.url_helpers.booking_page_url(sale_page.product.slug, from: "sale_page", from_id: sale_page.id)
    )
  end

  attribute :content do |sale_page|
    sale_page.content.merge(
      picture_url: Rails.application.routes.url_helpers.url_for(sale_page.picture.variant(combine_options: {
        resize: "750",
        flatten: true
      }))
    )
  end

  attribute :shop do |sale_page|
    ShopSerializer.new(sale_page.product.shop).attributes_hash
  end

  attribute :staff do |sale_page|
    StaffSerializer.new(sale_page.staff).attributes_hash
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
