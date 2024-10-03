class AddDefaultProviderToBookingPageOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :payment_option, :string, default: "offline"
    add_column :booking_page_options, :online_payment_enabled, :boolean, default: false

    BookingPage.where(online_payment_enabled: true).update_all(payment_option: "online")
    BookingPage.find_each do |booking_page|
      booking_page.booking_page_options.update_all(online_payment_enabled: booking_page.online_payment_enabled)
    end
  end
end