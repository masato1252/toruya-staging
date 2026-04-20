# frozen_string_literal: true

class AddStampRallyPhasesToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :stamp_rally_phases, :jsonb, default: [], null: false
  end
end
