class AddUseShopDefaultMessageToBookingPages < ActiveRecord::Migration[6.1]
  def change
    add_column :booking_pages, :use_shop_default_message, :boolean, default: true, null: false

    booking_page_ids = CustomMessage.where(service_type: "BookingPage").pluck(:service_id).uniq
    BookingPage.where(id: booking_page_ids).in_batches(of: 100) do |batch|
      batch.update_all(use_shop_default_message: false)
    end
  end
end