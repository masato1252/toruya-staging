class AddBenefitsReviewsFaqToSalePages < ActiveRecord::Migration[5.2]
  def change
    add_column :sale_pages, :sections_context, :jsonb, null: true
  end
end
