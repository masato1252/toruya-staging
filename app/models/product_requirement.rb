# == Schema Information
#
# Table name: product_requirements
#
#  id               :bigint           not null, primary key
#  requirement_type :string           not null
#  requirer_type    :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  requirement_id   :bigint           not null
#  requirer_id      :bigint           not null
#  sale_page_id     :integer
#
# Indexes
#
#  index_product_requirements_on_requirement   (requirement_type,requirement_id)
#  index_product_requirements_on_requirer      (requirer_type,requirer_id)
#  index_product_requirements_on_sale_page_id  (sale_page_id)
#
class ProductRequirement < ApplicationRecord
  belongs_to :requirer, polymorphic: true # BookingPage
  belongs_to :requirement, polymorphic: true # OnlineService
  belongs_to :sale_page, optional: true
end
