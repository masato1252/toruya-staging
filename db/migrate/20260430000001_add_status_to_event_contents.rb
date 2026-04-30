# frozen_string_literal: true

class AddStatusToEventContents < ActiveRecord::Migration[7.0]
  def change
    add_column :event_contents, :status, :integer, default: 1, null: false
    add_index :event_contents, :status
  end
end
