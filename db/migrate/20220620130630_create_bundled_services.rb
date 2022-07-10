class CreateBundledServices < ActiveRecord::Migration[6.0]
  def change
    create_table :bundled_services do |t|
      t.integer :bundler_online_service_id, null: false
      t.integer :online_service_id, null: false
      t.datetime :end_at
      t.integer :end_on_days
      t.integer :end_on_months
    end
  end
end
