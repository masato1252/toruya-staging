# frozen_string_literal: true

class EventSerializer
  include JSONAPI::Serializer

  attribute :id, :title, :slug, :description, :start_at, :end_at, :published

  attribute :hero_image_url do |event|
    if event.hero_image.attached?
      Rails.application.routes.url_helpers.rails_blob_url(event.hero_image, only_path: true)
    end
  end

  attribute :is_participant do |event, params|
    params[:participant].present?
  end

  attribute :is_logged_in do |event, params|
    params[:event_line_user].present?
  end

  attribute :contents do |event, params|
    event.event_contents.undeleted.order(:position).map do |content|
      event_line_user = params[:event_line_user]
      usage = event_line_user ? content.event_content_usages.find_by(event_line_user_id: event_line_user.id) : nil

      speakers = content.event_content_speakers.order(:position).map do |speaker|
        {
          name: speaker.name,
          position_title: speaker.position_title,
          profile_image_url: speaker.profile_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(speaker.profile_image, only_path: true) : nil
        }
      end

      if content.booth_content_type? && content.exhibitor_company_name.present?
        exhibitor = {
          name: content.exhibitor_company_name,
          picture_url: content.exhibitor_logo.attached? ? Rails.application.routes.url_helpers.rails_blob_url(content.exhibitor_logo, only_path: true) : nil,
          position: nil
        }
      else
        first_speaker = speakers.first
        if first_speaker
          exhibitor = { picture_url: first_speaker[:profile_image_url], position: first_speaker[:position_title], name: first_speaker[:name] }
        else
          staff = content.shop&.staffs&.first
          exhibitor = staff ? {
            picture_url: ApplicationController.helpers.staff_picture_url(staff, "360"),
            position: staff.position,
            name: staff.name
          } : nil
        end
      end

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
        monitor_limit: content.monitor_limit,
        speakers: speakers,
        exhibitor_staff: exhibitor,
        exhibitor_roles: content.exhibitor_roles || []
      }
    end
  end

  attribute :recommended_content_ids do |event, params|
    params[:recommended_content_ids] || []
  end
end
