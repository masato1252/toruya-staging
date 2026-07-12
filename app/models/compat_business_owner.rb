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

  def in_paid_plan?
    active? && plan_level.to_i.positive?
  end

  def charge_required
    @session_data.dig("plan", "charge_required") == true
  end

  def expired_date
    raw = @session_data.dig("plan", "trial_expired_date") || @session_data.dig("plan", "expired_date")
    return nil if raw.blank?

    Time.zone.parse(raw.to_s)
  rescue ArgumentError, TypeError
    nil
  end

  def next_plan
    nil
  end

  def plan
    CompatPlanProxy.new(@session_data)
  end

  def plan_level
    @session_data.dig("plan", "level").to_i
  end

  def stripe_customer_id
    nil
  end
end

class CompatPlanProxy
  def initialize(session_data)
    @session_data = session_data
  end

  def level
    @session_data.dig("plan", "level").to_i
  end

  def name
    @session_data.dig("plan", "name").presence || "plan"
  end

  def present?
    true
  end
end

# Lightweight stand-in for User when COMPAT_API_READ_ENABLED — no business AR reads.
class CompatSocialAccountProxy
  def initialize(session_data)
    @session_data = session_data
  end

  # Layout `_line_setup_prompt_modal` and settings rows call these on every page.
  def line_settings_finished?
    return true if @session_data["line_settings_finished"] == true
    return true if line_settings_verified?
    # Account row exists → treat credentials as configured (verification may still be pending).
    @session_data["social_account_present"] == true
  end

  def line_settings_verified?
    @session_data["line_settings_verified"] == true
  end

  def using_line_official_account?
    @session_data["using_line_official_account"] == true
  end

  def present?
    @session_data["social_account_present"] == true
  end
end

class CompatSocialUserProxy
  def initialize(session_data)
    @session_data = session_data
  end

  def id
    @session_data["social_user_id"]
  end

  def social_service_user_id
    @session_data["social_service_user_id"]
  end

  def present?
    social_service_user_id.present?
  end

  def single_owner?
    !@session_data["works_as_external_staff"] && @session_data["shops_count"].to_i <= 1
  end

  def manage_accounts
    []
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

  def locale_is?(target)
    locale.to_s.to_sym == target.to_s.to_sym
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

  def has_single_shop?
    if session_data.key?("multi_shop")
      session_data["multi_shop"] != true
    else
      session_data["shops_count"].to_i <= 1
    end
  end

  def team_plan_member?
    session_data["team_plan_member"] == true
  end

  def member_plan_name
    session_data.dig("plan", "name").presence || ""
  end

  def permission_level
    session_data.dig("plan", "level").to_i
  end

  def booking_options_menu_concept
    nil
  end

  def subscription
    @subscription ||= CompatSubscriptionProxy.new(session_data)
  end

  def social_account
    return nil unless session_data["social_account_present"]

    @social_account ||= CompatSocialAccountProxy.new(session_data)
  end

  def social_user
    return nil unless session_data["social_service_user_id"].present?

    @social_user ||= CompatSocialUserProxy.new(session_data)
  end

  # Empty relation stubs — never touch Heroku AR for ownership checks under compat.
  def customers
    CompatEmptyRelation.new
  end

  def shops
    CompatEmptyRelation.new
  end

  def ==(other)
    case other
    when User
      id == other.id
    when CompatBusinessOwner
      id == other.id
    when CompatCurrentUser
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
    user = ar_user
    if user&.respond_to?(method_name)
      user.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    ar_user&.respond_to?(method_name, include_private) || super
  end
end
