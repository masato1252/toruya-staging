class AddBookingPageReleatedColumnToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservation_customers, :booking_page_id, :integer
    add_column :reservation_customers, :booking_option_id, :integer
    add_column :reservation_customers, :details, :jsonb
  end
end
