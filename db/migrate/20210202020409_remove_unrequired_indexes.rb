# frozen_string_literal: true

class RemoveUnrequiredIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :booking_pages, name: "index_booking_pages_on_user_id"
    remove_index :social_customers, name: "index_social_customers_on_user_id"
    remove_index :social_users, name: "index_social_users_on_user_id"
  end
end
