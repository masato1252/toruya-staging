# frozen_string_literal: true

module EventContents
  class Update < ActiveInteraction::Base
    object :event_content

    string :content_type, default: nil
    string :title, default: nil
    string :description, default: nil
    string :introduction, default: nil
    integer :shop_id, default: nil
    integer :online_service_id, default: nil
    string :start_at, default: nil
    string :end_at, default: nil
    integer :capacity, default: nil
    integer :position, default: nil
    string :pre_ad_video_url, default: nil
    string :post_ad_video_url, default: nil
    string :direct_download_url, default: nil
    integer :upsell_booking_page_id, default: nil
    boolean :upsell_booking_enabled, default: nil
    boolean :monitor_enabled, default: nil
    string :monitor_name, default: nil
    integer :monitor_price, default: nil
    integer :monitor_limit, default: nil
    string :monitor_form_url, default: nil
    file :thumbnail, default: nil

    def execute
      attrs = {
        title: title,
        description: description,
        introduction: introduction,
        shop_id: shop_id,
        online_service_id: online_service_id,
        start_at: start_at.presence,
        end_at: end_at.presence,
        capacity: capacity,
        position: position,
        pre_ad_video_url: pre_ad_video_url,
        post_ad_video_url: post_ad_video_url,
        direct_download_url: direct_download_url,
        upsell_booking_page_id: upsell_booking_page_id,
        monitor_name: monitor_name,
        monitor_price: monitor_price,
        monitor_limit: monitor_limit,
        monitor_form_url: monitor_form_url
      }
      attrs[:content_type] = content_type if content_type.present?
      attrs[:upsell_booking_enabled] = upsell_booking_enabled unless upsell_booking_enabled.nil?
      attrs[:monitor_enabled] = monitor_enabled unless monitor_enabled.nil?

      if thumbnail
        event_content.thumbnail.purge if event_content.thumbnail.attached?
        event_content.thumbnail.attach(thumbnail)
      end

      unless event_content.update(attrs.compact)
        errors.merge!(event_content.errors)
      end

      event_content
    end
  end
end
