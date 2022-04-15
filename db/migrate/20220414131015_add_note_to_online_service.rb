class AddNoteToOnlineService < ActiveRecord::Migration[6.0]
  def change
    add_column :online_services, :note, :text
  end
end
