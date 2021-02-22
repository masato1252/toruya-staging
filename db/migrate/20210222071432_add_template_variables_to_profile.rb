class AddTemplateVariablesToProfile < ActiveRecord::Migration[5.2]
  def change
    add_column :profiles, :template_variables, :json
  end
end
