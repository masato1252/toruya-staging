class AddBeforeMinutesToCustomMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :custom_messages, :before_minutes, :integer
  end
end
