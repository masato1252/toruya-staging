class CreateSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :subscriptions do |t|
      t.references :plan
      t.references :user
      t.string :stripe_customer_id
      t.integer :status
      t.integer :recurring_day
      t.timestamps
    end
  end
end
