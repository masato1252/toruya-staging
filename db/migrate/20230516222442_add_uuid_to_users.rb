class AddUuidToUsers < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      add_column :users, :public_id, :uuid
      User.all.each do |u|
        u.update_columns(public_id: SecureRandom.uuid)
      end

      change_column_null(:users, :public_id, false)
      add_index :users, :public_id, unique: true
    end
  end
end
