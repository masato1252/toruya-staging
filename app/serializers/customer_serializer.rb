class CustomerSerializer
  include JSONAPI::Serializer

  attribute :id, :name, :address
end
