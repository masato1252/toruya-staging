class CreatePlans < ActiveRecord::Migration[5.1]
  def change
    create_table :plans do |t|
      t.integer :position
      t.integer :level
    end

    Plan.create(position: 0, level: :free)
    Plan.create(position: 1, level: :basic)
    Plan.create(position: 2, level: :premium)
  end
end
