# frozen_string_literal: true

class CreateContactGroupRankings < ActiveRecord::Migration[5.0]
  def change
    create_table :contact_group_rankings do |t|
      t.belongs_to :contact_group, index: true
      t.belongs_to :rank, index: true

      t.timestamps
    end
  end
end
