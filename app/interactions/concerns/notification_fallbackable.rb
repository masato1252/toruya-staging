module NotificationFallbackable
  # The core notification fallback logic that is the same in both classes
  # Returns the channel that was actually used for sending the notification
  def send_notification_with_fallbacks(preferred_channel: nil, custom_priority: nil)
    channels_by_priority = custom_priority || notification_priority_for(preferred_channel)

    channels_by_priority.each do |channel|
      next unless send_method_available?(channel)

      send_notification_via(channel)
      return channel  # Return the channel that was actually used
    end
    
    nil  # Return nil if no channel was available
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
    when "email", :email then %w[email line sms]
    when "sms", :sms then %w[sms email line]
    when "line", :line then %w[line email sms]
    else %w[line email sms]
    end
  end

  # Check if a notification method is available
  def send_method_available?(channel)
    case channel
    when "email", :email then available_to_send_email?
    when "sms", :sms then available_to_send_sms?
    when "line", :line then available_to_send_line?
    end
  end

  # Send notification via the specified channel
  def send_notification_via(channel)
    case channel
    when "email", :email then notify_by_email
    when "sms", :sms then notify_by_sms
    when "line", :line then notify_by_line
    end
  end
end
