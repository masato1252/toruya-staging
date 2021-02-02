# frozen_string_literal: true

class CreateStaffContactGroupRelations < ActiveRecord::Migration[5.1]
  def change
    create_table :staff_contact_group_relations do |t|
      t.references :staff, null: false
      t.references :contact_group, null: false
      t.integer :contact_group_read_permission, default: 0, null: false
      t.timestamps
    end

    add_index :staff_contact_group_relations, [:staff_id, :contact_group_id], name: "staff_contact_group_unique_index", unique: true
  end
end
