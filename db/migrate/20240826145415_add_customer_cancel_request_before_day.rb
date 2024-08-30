class AddCustomerCancelRequestBeforeDay < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :customer_cancel_request_before_day, :integer, null: false, default: 1
  end
end
