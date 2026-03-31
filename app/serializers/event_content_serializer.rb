# frozen_string_literal: true

class EventContentSerializer
  include JSONAPI::Serializer

  attribute :id, :title, :description, :introduction, :content_type
  attribute :start_at, :end_at, :capacity
  attribute :video_url, :pre_ad_video_url, :post_ad_video_url, :direct_download_url
  attribute :upsell_booking_enabled, :monitor_enabled
  attribute :monitor_name, :monitor_price, :monitor_limit, :monitor_form_url

  attribute :thumbnail_url do |content|
    content.thumbnail.attached? ? Rails.application.routes.url_helpers.rails_blob_url(content.thumbnail, only_path: true) : nil
  end

  attribute :slide_images do |content|
    content.event_content_images.order(:position).map do |img|
      {
        id: img.id,
        url: img.image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(img.image, only_path: true) : nil
      }
    end
  end

  attribute :started do |content|
    content.started?
  end

  attribute :ended do |content|
    content.ended?
  end

  attribute :capacity_full do |content|
    content.capacity_full?
  end

  attribute :usage_count do |content|
    content.usage_count
  end

  attribute :is_participant do |_, params|
    params[:participant].present?
  end

  attribute :is_logged_in do |_, params|
    params[:event_line_user].present?
  end

  attribute :has_started_usage do |_, params|
    params[:usage].present?
  end

  attribute :consultation_status do |_, params|
    params[:consultation]&.status
  end

  attribute :has_monitor_applied do |_, params|
    params[:monitor_application].present?
  end

  attribute :upsell_booking_page_url do |content|
    content.upsell_booking_page&.slug ? "/bookings/#{content.upsell_booking_page.slug}" : nil
  end

  attribute :online_service_registration_url do |content|
    content.online_service&.slug ? "/online_services/#{content.online_service.slug}" : nil
  end

  attribute :speakers do |content|
    content.event_content_speakers.order(:position).map do |speaker|
      {
        id: speaker.id,
        name: speaker.name,
        position_title: speaker.position_title,
        introduction: speaker.introduction,
        profile_image_url: speaker.profile_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(speaker.profile_image, only_path: true) : nil
      }
    end
  end

  attribute :exhibitor_staff do |content|
    speaker = content.event_content_speakers.order(:position).first
    if speaker
      return {
        picture_url: speaker.profile_image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(speaker.profile_image, only_path: true) : nil,
        position: speaker.position_title,
        name: speaker.name,
        introduction: speaker.introduction
      }
    end

    staff = content.shop&.staffs&.first
    return nil unless staff

    {
      picture_url: ApplicationController.helpers.staff_picture_url(staff, "360"),
      position: staff.position,
      name: staff.name,
      introduction: staff.introduction
    }
  end
end
