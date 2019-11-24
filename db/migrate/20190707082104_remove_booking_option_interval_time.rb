class RemoveBookingOptionIntervalTime < ActiveRecord::Migration[5.2]
  def change
    remove_column :booking_options, :interval
  end
end
