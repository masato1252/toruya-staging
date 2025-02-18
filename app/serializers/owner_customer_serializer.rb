
class OwnerCustomerSerializer
  include JSONAPI::Serializer

  attribute :first_name, :last_name, :phonetic_last_name, :phonetic_first_name, :customer_phone_number, :customer_email

  attribute :customer_id do |object|
    object.id
  end
end
