class CreateBusinessApplications < ActiveRecord::Migration[5.2]
  def change
    create_table :business_applications do |t|
      t.references :user, null: false
      t.integer :state, default: 0, null: false
      t.timestamps
    end
  end
end
