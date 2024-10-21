class AddBookingLimitHoursToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :booking_limit_hours, :integer, default: 0, null: false
  end
end
