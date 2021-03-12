# frozen_string_literal: true

class ShopFormSerializer
  include JSONAPI::Serializer
  attribute :id, :short_name, :name, :email, :holiday_working, :phone_number, :website, :template_variables, :address_details

  attribute :logo_url do |shop|
    ApplicationController.helpers.shop_logo_url(shop, "260", true)
  end
end
