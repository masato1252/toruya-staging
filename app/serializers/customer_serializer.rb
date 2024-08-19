# frozen_string_literal: true

class CustomerSerializer
  include JSONAPI::Serializer

  attribute :id, :name, :address, :reminder_permission
end
