class AddInternalNameToServices < ActiveRecord::Migration[6.0]
  def change
    add_column :online_services, :internal_name, :string
  end
end
