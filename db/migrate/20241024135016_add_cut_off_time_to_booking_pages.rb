class AddCutOffTimeToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :cut_off_time, :datetime, default: nil, null: true
  end
end