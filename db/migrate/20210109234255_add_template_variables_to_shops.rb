# frozen_string_literal: true

class AddTemplateVariablesToShops < ActiveRecord::Migration[5.2]
  def change
    add_column :shops, :template_variables, :json

    SalePage.find_each do |sale_page|
      shop = sale_page.product.shop

      shop.update(template_variables: sale_page.sale_template_variables)
    end
  end
end
