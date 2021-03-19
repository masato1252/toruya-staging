# frozen_string_literal: true

class AddUserIdToReservations < ActiveRecord::Migration[5.2]
  def change
    add_column :reservations, :user_id, :integer
    remove_index :reservations, name: :index_reservations_on_shop_id_and_deleted_at
    add_index :reservations, [:user_id, :shop_id, :deleted_at], name: :reservation_user_shop_index
    remove_index :reservations, name: :reservation_index
    add_index :reservations, %i(user_id shop_id aasm_state menu_id start_time ready_time), name: :reservation_query_index

    Reservation.find_each do |reservation|
      reservation.update(user_id: reservation.shop.user_id)
    end
  end
end
