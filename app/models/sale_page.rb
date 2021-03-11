# frozen_string_literal: true
# == Schema Information
#
# Table name: sale_pages
#
#  id                         :bigint(8)        not null, primary key
#  user_id                    :bigint(8)
#  staff_id                   :bigint(8)
#  product_type               :string           not null
#  product_id                 :bigint(8)        not null
#  sale_template_id           :bigint(8)
#  sale_template_variables    :json
#  content                    :json
#  flow                       :json
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  slug                       :string
#  introduction_video_url     :string
#  quantity                   :integer
#  selling_end_at             :datetime
#  selling_start_at           :datetime
#  normal_price_amount_cents  :decimal(, )
#  selling_price_amount_cents :decimal(, )
#
# Indexes
#
#  index_sale_pages_on_product_type_and_product_id  (product_type,product_id)
#  index_sale_pages_on_sale_template_id             (sale_template_id)
#  index_sale_pages_on_slug                         (slug) UNIQUE
#  index_sale_pages_on_staff_id                     (staff_id)
#  index_sale_pages_on_user_id                      (user_id)
#

class SalePage < ApplicationRecord
  belongs_to :product, polymorphic: true
  belongs_to :staff
  belongs_to :sale_template

  has_one_attached :picture
end
