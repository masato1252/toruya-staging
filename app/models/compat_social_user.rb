# frozen_string_literal: true

# Lightweight stand-in for SocialUser when COMPAT_API_READ_ENABLED — no social_users AR reads.
class CompatSocialUser
  attr_reader :session_data

  def initialize(session_data)
    @session_data = session_data
  end

  def id
    session_data["social_user_id"]
  end

  def social_service_user_id
    session_data["social_service_user_id"]
  end

  def social_user_name
    session_data["social_user_name"]
  end

  def social_user_picture_url
    session_data["social_user_picture_url"]
  end

  def locale
    session_data["social_user_locale"] || session_data["locale"] || "ja"
  end

  def user_id
    session_data["current_user_id"] || session_data["owner_id"]
  end

  def user
    CompatCurrentUser.new(session_data)
  end

  def current_users
    [CompatCurrentUser.new(session_data)]
  end

  def root_user
    CompatBusinessOwner.new(session_data)
  end

  def super_admin?
    session_data["is_super_admin"] == true
  end

  def single_owner?
    true
  end

  def manage_accounts
    # Prefer linked SocialUser accounts when AR is available (multi-account owners).
    linked = ar_social_user
    if linked&.respond_to?(:manage_accounts)
      accounts = linked.manage_accounts
      return accounts if accounts.present?
    end
    [CompatBusinessOwner.new(session_data)]
  end

  def ==(other)
    case other
    when SocialUser
      social_service_user_id == other.social_service_user_id
    when CompatSocialUser
      social_service_user_id == other.social_service_user_id
    else
      false
    end
  end

  def is_a?(klass)
    klass == SocialUser || super
  end

  def ar_social_user
    return nil unless social_service_user_id

    @ar_social_user ||= SocialUser.linked_for_line(social_service_user_id) ||
                        SocialUser.find_by(social_service_user_id: social_service_user_id)
  end

  def method_missing(method_name, *args, &block)
    target = ar_social_user
    if target&.respond_to?(method_name)
      target.public_send(method_name, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    ar_social_user&.respond_to?(method_name, include_private) || super
  end
end
