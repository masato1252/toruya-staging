# frozen_string_literal: true

class CompatSubscriptionProxy
  def initialize(session_data)
    @session_data = session_data
  end

  def over_free_limit?
    @session_data["over_free_limit"] == true
  end

  def active?
    @session_data.dig("plan", "active") != false
  end
end

# Lightweight stand-in for User when COMPAT_API_READ_ENABLED — no business AR reads.
class CompatSocialAccountProxy
  def initialize(session_data)
    @session_data = session_data
  end

  def line_settings_verified?
    @session_data["line_settings_verified"] == true
  end

  def using_line_official_account?
    false
  end

  def present?
    @session_data["social_account_present"] == true
  end
end

class CompatBusinessOwner
  attr_reader :session_data

  def initialize(session_data)
    @session_data = session_data
  end

  def id
    session_data["owner_id"]
  end

  def locale
    session_data["locale"] || "ja"
  end

  def timezone
    locale_key = locale.to_s.to_sym
    ::LOCALE_TIME_ZONE[locale_key] || "Asia/Tokyo"
  end

  def company_name
    session_data["company_name"]
  end

  def name
    session_data["display_name"].presence || company_name.presence || "Owner"
  end

  def customer_notification_channel
    session_data["customer_notification_channel"] || "email"
  end

  # Prefer Supabase-backed session (toggle_mode writes there). Never fall through
  # to Heroku AR via method_missing — that is a stale clone on staging.
  def schedule_mode
    mode = session_data["schedule_mode"].presence
    mode == "calendar" ? "calendar" : "list"
  end

  def support_toruya_message_reply?
    session_data["toruya_message_reply"] == true
  end

  def premium_member?
    session_data.dig("plan", "active") == true
  end

  def subscription
    @subscription ||= CompatSubscriptionProxy.new(session_data)
  end

  def social_account
    return nil unless session_data["social_account_present"]

    @social_account ||= CompatSocialAccountProxy.new(session_data)
  end

  def ==(other)
    case other
    when User
      id == other.id
    when CompatBusinessOwner
      id == other.id
    else
      false
    end
  end

  def is_a?(klass)
    klass == User || super
  end

  # Mutations still delegate to AR until write-path cutover.
  def ar_user
    @ar_user ||= User.find_by(id: id)
  end

  def method_missing(method_name, *args, &block)
    if ar_user.respond_to?(method_name)
      ar_user.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    ar_user.respond_to?(method_name, include_private) || super
  end
end
