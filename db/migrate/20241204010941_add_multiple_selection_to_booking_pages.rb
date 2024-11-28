class AddMultipleSelectionToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :multiple_selection, :boolean, default: false
  end
end
