# frozen_string_literal: true

class BundledServiceSerializer
  include JSONAPI::Serializer

  attribute :end_time, :end_time_text

  attribute :id do |bundled_service|
    bundled_service.online_service_id
  end

  attribute :label do |bundled_service|
    bundled_service.online_service.name
  end
end
