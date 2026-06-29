# frozen_string_literal: true

class ProfileSerializer
  include JSONAPI::Serializer

  attribute :id, &:user_id
  attribute :name
  attribute :address, &:company_full_address
  attribute :personal_address, &:personal_full_address

  attribute :shops do |profile|
    profile.user.shops.order(:id).map do |shop|
      {
        id: shop.id,
        name: shop.read_attribute(:name),
        address: shop.company_full_address
      }
    end
  end
end
