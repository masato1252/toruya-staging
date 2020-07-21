class AddLineSharingToBookingPage < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_pages, :line_sharing, :boolean, default: true
    add_index :booking_pages, [:user_id, :draft, :line_sharing, :start_at], name: :booking_page_index
  end
end
