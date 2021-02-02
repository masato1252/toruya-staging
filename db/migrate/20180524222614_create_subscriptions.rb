# frozen_string_literal: true

class CreateSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :subscriptions do |t|
      t.references :plan
      t.integer :next_plan_id
      t.references :user
      t.string :stripe_customer_id
      t.integer :recurring_day
      t.date :expired_date
      t.timestamps
    end
  end
end
