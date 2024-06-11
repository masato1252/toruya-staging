class AddSkipSocialCustomerToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :social_account_skippable, :boolean, default: false, null: false
  end
end
