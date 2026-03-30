# frozen_string_literal: true

class CreateEventContents < ActiveRecord::Migration[7.0]
  def change
    create_table :event_contents do |t|
      t.references :event, null: false, foreign_key: true
      t.references :shop, null: true, foreign_key: true
      t.references :online_service, null: true, foreign_key: true
      t.integer :content_type, null: false, default: 0
      t.string :title, null: false
      t.text :description
      t.text :introduction
      t.datetime :start_at
      t.datetime :end_at
      t.integer :capacity
      t.integer :position, default: 0, null: false

      # seminar video
      t.string :pre_ad_video_url
      t.string :post_ad_video_url
      t.string :direct_download_url

      # upsell
      t.references :upsell_booking_page, null: true, foreign_key: { to_table: :booking_pages }
      t.boolean :upsell_booking_enabled, default: false, null: false

      # monitor
      t.boolean :monitor_enabled, default: false, null: false
      t.string :monitor_name
      t.integer :monitor_price
      t.integer :monitor_limit
      t.string :monitor_form_url

      t.datetime :deleted_at

      t.timestamps
    end

    add_index :event_contents, :deleted_at
    add_index :event_contents, [:event_id, :position]

    create_table :event_content_images do |t|
      t.references :event_content, null: false, foreign_key: true
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :event_content_images, [:event_content_id, :position]
  end
end
