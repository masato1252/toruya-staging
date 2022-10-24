# frozen_string_literal: true

class BundleableServiceSerializer
  include JSONAPI::Serializer

  attribute :id

  attribute :label do |online_service|
    online_service.internal_name.presence || online_service.name
  end

  attribute :end_time_options do |online_service|
    if online_service.membership?
      [ 'end_on_months', 'subscription' ]
    else
      [ 'end_at', 'end_on_days', 'end_on_months', 'never', 'subscription' ]
    end
  end
end
