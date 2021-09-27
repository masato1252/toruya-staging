class AddOnlinePaymentToBookingPages < ActiveRecord::Migration[6.0]
  def change
    add_column :booking_pages, :online_payment_enabled, :boolean
    change_column_default :booking_pages, :online_payment_enabled, false

    BookingPage.update_all(online_payment_enabled: false)
  end
end
