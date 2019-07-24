class AddDraftToBookingPage < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_pages, :draft, :boolean, default: true, null: false
  end
end
