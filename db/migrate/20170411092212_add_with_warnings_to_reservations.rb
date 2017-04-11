class AddWithWarningsToReservations < ActiveRecord::Migration[5.0]
  def change
    add_column :reservations, :with_warnings, :boolean, default: false, null: false
  end
end
