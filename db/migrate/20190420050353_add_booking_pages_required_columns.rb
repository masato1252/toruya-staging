# frozen_string_literal: true

class AddBookingPagesRequiredColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_pages, :start_at, :datetime
    add_column :booking_pages, :end_at, :datetime
    add_column :booking_pages, :overbooking_restriction, :boolean, default: true

    create_table :booking_page_special_dates do |t|
      t.references :booking_page, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.timestamps
    end
  end
end
