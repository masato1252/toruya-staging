# frozen_string_literal: true

class BusinessScheduleSerializer
  include JSONAPI::Serializer

  attribute :id, :shop_id, :business_state, :day_of_week

  attribute :start_time do |object|
    object.start_time && I18n.l(object.start_time, format: :time_only)
  end

  attribute :end_time do |object|
    object.end_time && I18n.l(object.end_time, format: :time_only)
  end
end
