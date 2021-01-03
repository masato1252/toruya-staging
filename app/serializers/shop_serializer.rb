class ShopSerializer
  include JSONAPI::Serializer
  attribute :id, :email, :phone_number

  attribute :logo_url do |shop|
    ApplicationController.helpers.shop_logo_url(shop, "390x135")
  end

  attribute :name do |shop|
    shop.display_name
  end

  attribute :address do |shop|
    "〒#{shop.zip_code} #{shop.address}" if shop.address.present?
  end
end
