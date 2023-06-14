class AddEventBookingToBookingPage < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :event_booking, :boolean, default: false
  end
end
