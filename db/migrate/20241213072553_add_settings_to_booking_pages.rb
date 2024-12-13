class AddSettingsToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :settings, :jsonb, default: {}, null: false
    BookingPage.update_all(settings: { customer_address_required: true })
  end
end
