class AddDeleteAtToBookingPages < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_pages, :deleted_at, :datetime, null: true
    remove_index :booking_pages, name: :booking_page_index
    add_index :booking_pages, [:user_id, :deleted_at, :draft], name: :booking_page_index
  end
end
