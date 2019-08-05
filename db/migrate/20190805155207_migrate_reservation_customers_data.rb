class MigrateReservationCustomersData < ActiveRecord::Migration[5.2]
  def change
    ReservationCustomer.update_all(state: "accepted")
  end
end
