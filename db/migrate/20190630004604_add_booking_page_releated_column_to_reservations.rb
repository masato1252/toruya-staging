class AddBookingPageReleatedColumnToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservation_customers, :booking_page_id, :integer
    add_column :reservation_customers, :booking_option_id, :integer
    add_column :reservation_customers, :state, :integer, default: 0
    add_column :reservation_customers, :booking_amount_currency, :string
    add_column :reservation_customers, :booking_amount_cents, :decimal
    add_column :reservation_customers, :tax_include, :boolean
    add_column :reservation_customers, :booking_at, :datetime
    add_column :reservation_customers, :details, :jsonb

    add_column :reservation_menus, :required_time, :integer

    ReservationMenu.where(required_time: nil).find_each do |reservation_menu|
      reservation_menu.update_columns(required_time:  reservation_menu.menu.minutes, position: 0)
    end
  end
end
