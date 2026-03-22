# frozen_string_literal: true

class EventSerializer
  include JSONAPI::Serializer

  attribute :id, :title, :slug, :description, :start_at, :end_at, :published

  attribute :is_participant do |event, params|
    params[:participant].present?
  end

  attribute :contents do |event, params|
    event.event_contents.undeleted.order(:position).map do |content|
      social_user = params[:social_user]
      usage = social_user ? content.event_content_usages.find_by(social_user_id: social_user.id) : nil

      {
        id: content.id,
        content_type: content.content_type,
        title: content.title,
        introduction: content.introduction,
        thumbnail_url: content.thumbnail.attached? ? Rails.application.routes.url_helpers.rails_blob_url(content.thumbnail, only_path: true) : nil,
        start_at: content.start_at,
        end_at: content.end_at,
        capacity: content.capacity,
        usage_count: content.usage_count,
        capacity_full: content.capacity_full?,
        started: content.started?,
        ended: content.ended?,
        has_started_usage: usage.present?,
        upsell_booking_enabled: content.upsell_booking_enabled,
        monitor_enabled: content.monitor_enabled,
        monitor_name: content.monitor_name,
        monitor_price: content.monitor_price,
        monitor_limit: content.monitor_limit
      }
    end
  end

  attribute :line_login_url do |event, params|
    # Returns the LINE login URL for event participation
    nil
  end
end
