# frozen_string_literal: true

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

  def company_name
    session_data["company_name"]
  end

  def name
    session_data["display_name"].presence || company_name.presence || "Owner"
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
end
