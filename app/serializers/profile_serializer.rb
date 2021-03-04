# frozen_string_literal: true

class ProfileSerializer
  include JSONAPI::Serializer

  attribute :id, &:user_id
  attribute :name
  attribute :address, &:company_full_address
end
