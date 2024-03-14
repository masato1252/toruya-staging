class AddPositionToBookingPageOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_page_options, :position, :integer, default: 0
  end
end
