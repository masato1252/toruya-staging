# frozen_string_literal: true

module JSONAPI::Serializer
  def attributes_hash
    serializable_hash.dig(:data, :attributes)
  end
end
