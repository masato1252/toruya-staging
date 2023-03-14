class AddDeleteAtToBookingOptions < ActiveRecord::Migration[6.0]
  def change
    add_column :booking_options, :delete_at, :datetime
  end
end
