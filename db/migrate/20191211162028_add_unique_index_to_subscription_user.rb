# frozen_string_literal: true

class AddUniqueIndexToSubscriptionUser < ActiveRecord::Migration[5.2]
  def change
    remove_index :subscriptions, :user_id
    add_index :subscriptions, :user_id, unique: true
  end
end
