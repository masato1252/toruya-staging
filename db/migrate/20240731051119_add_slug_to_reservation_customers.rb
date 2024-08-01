class AddSlugToReservationCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :reservation_customers, :slug, :string
    add_index :reservation_customers, :slug, unique: true

    ReservationCustomer.find_each do |reservation_customer|
      reservation_customer.update(slug: SecureRandom.alphanumeric(10))
    end
  end
end
