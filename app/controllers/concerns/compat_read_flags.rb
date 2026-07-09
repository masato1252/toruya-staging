# frozen_string_literal: true

# Shared compat read gate — requires both flag and v1 API origin.
module CompatReadFlags
  extend ActiveSupport::Concern

  included do
    helper_method :compat_read_enabled?, :compat_read_data_plane? if respond_to?(:helper_method)
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

  def compat_read_enabled?
    compat_read_data_plane?
  end

  def current_data_plane_owner_id
    if respond_to?(:business_owner_id, true)
      id = business_owner_id
      return id if id.present?
    end

    resolve_compat_owner_id(nil)
  end

  def resolve_compat_id(value)
    return nil if value.blank?

    id = value.to_i
    id.positive? ? id : nil
  end
end
