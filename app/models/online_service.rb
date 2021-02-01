# == Schema Information
#
# Table name: online_services
#
#  id                  :bigint(8)        not null, primary key
#  user_id             :bigint(8)
#  name                :string           not null
#  goal_type           :string           not null
#  solution_type       :string           not null
#  end_at              :datetime
#  end_on_days         :integer
#  upsell_sale_page_id :integer
#  content             :json
#  company_type        :string           not null
#  company_id          :bigint(8)        not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_online_services_on_user_id  (user_id)
#

class OnlineService < ApplicationRecord
  belongs_to :user
  belongs_to :sale_page, foreign_key: :upsell_sale_page_id, required: false
  belongs_to :company, polymorphic: true
end
