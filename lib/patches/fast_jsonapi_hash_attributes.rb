module JSONAPI::Serializer
  def attributes_hash
    serializable_hash[:data][:attributes]
  end
end
