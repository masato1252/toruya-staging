# frozen_string_literal: true

class AddStampRallyDescriptionToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :stamp_rally_description, :text
  end
end
