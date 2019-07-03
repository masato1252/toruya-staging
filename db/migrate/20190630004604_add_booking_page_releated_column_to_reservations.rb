class AddBookingPageReleatedColumnToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservation_customers, :booking_page_id, :integer
    add_column :reservation_customers, :booking_option_id, :integer
    add_column :reservation_customers, :state, :integer, default: 0
    add_column :reservation_customers, :amount_currency, :string
    add_column :reservation_customers, :amount_cents, :decimal
    add_column :reservation_customers, :tax_include, :boolean
    add_column :reservation_customers, :details, :jsonb
  end
end
