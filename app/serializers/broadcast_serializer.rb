# frozen_string_literal: true

class BroadcastSerializer
  include JSONAPI::Serializer
  attribute :id, :query, :content, :query_type

  attribute :schedule_at do |object|
    object.schedule_at ? I18n.l(object.schedule_at, format: :local_time) : nil
  end
end
