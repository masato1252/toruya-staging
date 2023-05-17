class ProcessActionInstrument
  def call(name, started, finished, unique_id, payload)
    return unless payload[:status]&.in? 200..399
    return if payload[:path].starts_with?('/rails')
    return if Current.user.nil? && Current.customer.nil?

    if Rails.configuration.x.env.production?
      ::TrackProcessedActionJob.perform_later(Current.user, event_name(payload), event_properties(payload)) if Current.user
      ::TrackProcessedActionJob.perform_later(Current.customer, event_name(payload), event_properties(payload)) if Current.customer
    end
  end

  private

  def event_name(payload)
    "#{payload[:controller]}##{payload[:action]}"
  end

  def event_properties(payload)
    params = payload[:params]

    params.tap do |props|
      props.update Current.mixpanel_extra_properties if Current.mixpanel_extra_properties
    end
  end
end
