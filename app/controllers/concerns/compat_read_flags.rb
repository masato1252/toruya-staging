# frozen_string_literal: true

# Shared compat read gate — requires both flag and v1 API origin.
module CompatReadFlags
  extend ActiveSupport::Concern

  included do
    helper_method :compat_read_enabled?, :compat_read_data_plane?, :compat_admin_enabled?, :compat_public_read_for_owner? if respond_to?(:helper_method)
  end

  def compat_api_configured?
    ENV["COMPAT_API_ORIGIN"].present?
  end

  def compat_read_data_plane?
    return false unless ENV["COMPAT_API_READ_ENABLED"] == "true"
    return false unless compat_api_configured?

    owner_id = current_data_plane_owner_id
    owner_id.present? && DataPlaneMigration.migrated?(owner_id)
  end

  # Admin reads and writes are authorized by the Rails admin session and the
  # signed server proxy. They must not depend on an owner migration cookie.
  def compat_admin_enabled?
    ENV["COMPAT_API_READ_ENABLED"] == "true" && compat_api_configured?
  end

  # Public customer surfaces (booking/sale/OS/survey) have no owner cookie —
  # gate by product owner id instead of Current.business_owner.
  def compat_public_read_for_owner?(owner_id)
    return false unless ENV["COMPAT_API_READ_ENABLED"] == "true"
    return false unless compat_api_configured?

    id = resolve_compat_id(owner_id)
    id.present? && DataPlaneMigration.migrated?(id)
  end

  def compat_read_enabled?
    compat_read_data_plane?
  end

  # Must NOT call business_owner / super_user / business_owner_id / current_user —
  # those call compat_read_data_plane? and recurse when business_owner_id is absent.
  def current_data_plane_owner_id
    id = resolve_compat_id(params[:business_owner_id])
    return id if id

    if defined?(Current) && Current.respond_to?(:business_owner) && Current.business_owner.respond_to?(:id)
      id = resolve_compat_id(Current.business_owner.id)
      return id if id
    end

    if respond_to?(:user_bot_cookies, true)
      id = resolve_compat_id(user_bot_cookies(:current_user_id))
      return id if id
    end

    nil
  end

  def resolve_compat_id(value)
    return nil if value.blank?

    id = value.to_i
    id.positive? ? id : nil
  end
end
