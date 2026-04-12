# frozen_string_literal: true

class CleanupConcernColumnsAndAddExhibitorRoles < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      remove_column :event_participants, :concern_label, :string
      remove_column :event_participants, :concern_category, :string
    end

    add_column :event_participants, :concern_categories, :jsonb, null: false, default: []

    add_column :event_contents, :exhibitor_roles, :jsonb, null: false, default: []
  end
end
