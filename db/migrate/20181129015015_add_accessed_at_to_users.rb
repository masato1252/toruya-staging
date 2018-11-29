class AddAccessedAtToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :accessed_at, :datetime
  end
end
