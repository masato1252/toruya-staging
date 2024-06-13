class AddBookingPageIdToBusinessSchedules < ActiveRecord::Migration[7.0]
  def change
    add_column :business_schedules, :booking_page_id, :integer
    add_index :business_schedules, :booking_page_id
  end
end
