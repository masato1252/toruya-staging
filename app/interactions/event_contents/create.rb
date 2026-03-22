# frozen_string_literal: true

module EventContents
  class Create < ActiveInteraction::Base
    object :event

    string :content_type
    string :title
    string :description, default: nil
    string :introduction, default: nil
    integer :shop_id, default: nil
    integer :online_service_id, default: nil
    string :start_at, default: nil
    string :end_at, default: nil
    integer :capacity, default: nil
    integer :position, default: 0
    string :pre_ad_video_url, default: nil
    string :post_ad_video_url, default: nil
    string :direct_download_url, default: nil
    integer :upsell_booking_page_id, default: nil
    boolean :upsell_booking_enabled, default: false
    boolean :monitor_enabled, default: false
    string :monitor_name, default: nil
    integer :monitor_price, default: nil
    integer :monitor_limit, default: nil
    string :monitor_form_url, default: nil
    file :thumbnail, default: nil

    validates :title, presence: true

    def execute
      event_content = event.event_contents.build(
        content_type: content_type,
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
        upsell_booking_enabled: upsell_booking_enabled,
        monitor_enabled: monitor_enabled,
        monitor_name: monitor_name,
        monitor_price: monitor_price,
        monitor_limit: monitor_limit,
        monitor_form_url: monitor_form_url
      )

      if thumbnail
        event_content.thumbnail.attach(thumbnail)
      end

      unless event_content.save
        errors.merge!(event_content.errors)
        return
      end

      event_content
    end
  end
end
