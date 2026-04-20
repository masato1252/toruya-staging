class AddEmailToEventLineUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :event_line_users, :email, :string
    add_index :event_line_users, :email
  end
end
