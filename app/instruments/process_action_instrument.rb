class ProcessActionInstrument
  def call(name, started, finished, unique_id, payload)
    return unless payload[:status]&.in? 200..399
    return if payload[:path].starts_with?('/rails', '/admin')
    return if Current.user.nil? && Current.customer.nil?

    if Rails.configuration.x.env.production? && supported_arguments(payload)
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

  def supported_arguments(payload)
    params = payload[:params]
    return false if invalid_params_check(params)
    return true
  end

  def invalid_params_check(params)
    params.any? do |_, v|
      if v.is_a?(ActionDispatch::Http::UploadedFile)
        return true
      elsif v.is_a?(Hash)
        invalid_params_check(v)
      end
    end
  end
end
