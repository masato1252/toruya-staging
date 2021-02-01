class ShopSerializer
  include JSONAPI::Serializer
  attribute :id, :short_name, :email, :phone_number, :template_variables
  attribute :label, &:display_name

  attribute :logo_url do |shop|
    ApplicationController.helpers.shop_logo_url(shop, "260")
  end

  attribute :name do |shop|
    shop.display_name
  end

  attribute :address do |shop|
    "〒#{shop.zip_code} #{shop.address}" if shop.address.present?
  end
end
