class RenameUsersAccessedAt < ActiveRecord::Migration[5.1]
  def change
    rename_column :users, :accessed_at, :contacts_sync_at
  end
end
