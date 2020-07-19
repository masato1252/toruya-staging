class CustomerSerializer
  include FastJsonapi::ObjectSerializer

  attribute :id, :name, :address
end
