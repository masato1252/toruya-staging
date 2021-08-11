class AddAvaiableBookingStartTimesToBookingPage < ActiveRecord::Migration[6.0]
  def change
    add_column :booking_pages, :specific_booking_start_times, :string, array: true
  end
end
