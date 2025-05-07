module NotificationFallbackable
  # The core notification fallback logic that is the same in both classes
  def send_notification_with_fallbacks(preferred_channel: nil, custom_priority: nil)
    channels_by_priority = custom_priority || notification_priority_for(preferred_channel)

    channels_by_priority.each do |channel|
      next unless send_method_available?(channel)

      send_notification_via(channel)
      break
    end
  end

  # Send notifications to all available channels in the provided list
  # without stopping after the first one
  def send_notification_to_all_channels(channels)
    channels.each do |channel|
      next unless send_method_available?(channel)

      send_notification_via(channel)
    end
  end

  def notification_priority_for(preferred_channel)
    case preferred_channel
    when "email", :email then %w[email]
    when "line", :line then %w[line email]
    else %w[line email]
    end
  end

  # Check if a notification method is available
  def send_method_available?(channel)
    case channel
    when "email", :email then available_to_send_email?
    when "line", :line then available_to_send_line?
    end
  end

  # Send notification via the specified channel
  def send_notification_via(channel)
    case channel
    when "email", :email then notify_by_email
    when "line", :line then notify_by_line
    end
  end
end