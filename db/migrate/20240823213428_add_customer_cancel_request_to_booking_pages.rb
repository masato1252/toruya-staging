class AddCustomerCancelRequestToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :customer_cancel_request, :boolean, default: false
  end
end
