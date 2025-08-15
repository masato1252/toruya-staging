# frozen_string_literal: true

class MenuSerializer
  include JSONAPI::Serializer
  attribute :id, :short_name, :name, :minutes, :interval, :online, :min_staffs_number
end
