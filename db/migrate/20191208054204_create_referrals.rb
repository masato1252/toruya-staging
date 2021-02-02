# frozen_string_literal: true

class CreateReferrals < ActiveRecord::Migration[5.2]
  def up
    create_table :referrals do |t|
      t.integer :referrer_id, null: false
      t.integer :referee_id, null: false
      t.integer :state, default: 0, null: false

      t.timestamps
    end

    add_index :referrals, [:referrer_id], unique: true

    Plan.create(position: 3, level: :business)
    Plan.create(position: 4, level: :child_basic)
    Plan.create(position: 5, level: :child_premium)
  end

  def down
    drop_table :referrals
    Plan.where(level: :business).destroy_all
    Plan.where(level: :child_basic).destroy_all
    Plan.where(level: :child_premium).destroy_all
  end
end
