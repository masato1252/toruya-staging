class AddBookingPagesRequiredColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_pages, :start_at, :datetime
    add_column :booking_pages, :end_at, :datetime
  end
end
