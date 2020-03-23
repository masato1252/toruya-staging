class AddLimitingDayToBookingPage < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_pages, :booking_limit_day, :integer, default: 1, null: false
  end
end
