require "mixpanel_tracker"

class TrackProcessedActionJob < ApplicationJob
  queue_as :low

  def perform(tracking_object, event_name, event_properties)
    if tracking_object.is_a?(User)
      mixpanel_client.track tracking_object.public_id, event_name, event_properties

      return unless people_set_recent?(tracking_object)

      mixpanel_client.people.set(
        tracking_object.public_id,
        {
          '$name' => tracking_object.name,
          '$created' => tracking_object.created_at,
          '$last_seen' => tracking_object.current_sign_in_at,
          '$sign_in_count' => tracking_object.sign_in_count,
          '$customer_latest_activity_at' => tracking_object.customer_latest_activity_at
        },
        0,
        '$ignore_time' => 'true'
      )
      tracking_object.update_column :mixpanel_profile_last_set_at, Time.current
    elsif tracking_object.is_a?(Customer)
      mixpanel_client.track tracking_object.id, event_name, event_properties

      return unless people_set_recent?(tracking_object)

      mixpanel_client.people.set(
        tracking_object.id,
        {
          '$name' => tracking_object.name,
          '$created' => tracking_object.created_at,
          '$menus_count' => tracking_object.menu_ids.size,
          '$services_count' => tracking_object.online_service_ids.size,
        },
        0,
        '$ignore_time' => 'true'
      )
      tracking_object.update_column :mixpanel_profile_last_set_at, Time.current
    else
      mixpanel_client.track tracking_object, event_name, event_properties
    end


  end

  private

  def mixpanel_client
    @mixpanel_client ||= Mixpanel::Tracker.new(MixpanelTracker::MIXPANEL_TOKEN)
  end

  def people_set_recent?(tracking_object)
    tracking_object.mixpanel_profile_last_set_at.nil? || tracking_object.mixpanel_profile_last_set_at < 3.days.ago
  end
end
