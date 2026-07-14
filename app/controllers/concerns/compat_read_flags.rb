# frozen_string_literal: true

# Shared compat read gate — requires both flag and v1 API origin.
module CompatReadFlags
  extend ActiveSupport::Concern

  included do
    helper_method(
      :compat_read_enabled?,
      :compat_read_data_plane?,
      :compat_admin_enabled?,
      :compat_event_enabled?,
      :compat_public_read_for_owner?,
      :compat_public_event_for_owner?,
      :compat_public_event_for_viewer?,
      :compat_event_frontend_enabled?,
      :compat_event_context_query
    ) if respond_to?(:helper_method)
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
    ENV["COMPAT_ADMIN_ENABLED"] == "true" && compat_api_configured?
  end

  # Public event auth/SSR entry points check the env flag before owner migration
  # is known. Owner migration is enforced by compat_public_event_for_owner?.
  def compat_event_enabled?
    ENV["COMPAT_EVENT_ENABLED"] == "true" && compat_api_configured?
  end

  # Public customer surfaces (booking/sale/OS/survey) have no owner cookie —
  # gate by product owner id instead of Current.business_owner.
  def compat_public_read_for_owner?(owner_id)
    return false unless ENV["COMPAT_API_READ_ENABLED"] == "true"
    return false unless compat_api_configured?

    id = resolve_compat_id(owner_id)
    id.present? && DataPlaneMigration.migrated?(id)
  end

  # Event administration and its public frontend are switched independently
  # from booking/customer compat. The event owner must also be migrated so
  # disabling the flag always restores the complete legacy event route.
  def compat_public_event_for_owner?(owner_id)
    return false unless compat_event_enabled?

    id = resolve_compat_id(owner_id)
    id.present? && DataPlaneMigration.migrated?(id)
  end

  # Registered Toruya users keep the data plane of their own owner/shop data
  # during migration for affiliation resolution. Event/content records still
  # follow the event owner's plane; legacy shop ids are signed into API reads.
  def compat_public_event_for_viewer?(owner_id)
    compat_public_event_for_owner?(owner_id)
  end

  def compat_event_frontend_enabled?
    return true if @compat_public_read

    @compat_event.present? || @compat_event_content_context.present?
  end

  def compat_event_context_query
    {
      event_line_user_id: session[:event_line_user_id],
      legacy_shop_ids: Array(session[:event_legacy_shop_ids]).presence&.join(",")
    }.compact
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
