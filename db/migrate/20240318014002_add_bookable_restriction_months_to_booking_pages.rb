class AddBookableRestrictionMonthsToBookingPages < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_pages, :bookable_restriction_months, :integer, default: 3
  end
end
