class MixpanelTracker
  MIXPANEL_TOKEN = "2f6fae2aea33cb07b903b7e1d719a5b4"

  def self.track(target_id, event_name, details = {})
    return unless Rails.env.production?

    mixpanel = Mixpanel::Tracker.new MIXPANEL_TOKEN

    mixpanel.track target_id, event_name, details
  end
end

