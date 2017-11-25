class AddNameToFilterOutcome < ActiveRecord::Migration[5.1]
  def change
    add_column :filtered_outcomes, :name, :string
  end
end
