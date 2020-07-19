module FastJsonapi::ObjectSerializer
  def attributes_hash
    serializable_hash[:data][:attributes]
  end
end
