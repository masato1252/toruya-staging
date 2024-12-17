class AddLabelToFunctionAccesses < ActiveRecord::Migration[7.0]
  def change
    add_column :function_accesses, :label, :string
    add_index :function_accesses, [:access_date, :source_id, :label], name: "index_function_accesses_on_date_and_source_and_label"
  end
end
