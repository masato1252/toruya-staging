# == Schema Information
#
# Table name: customers
#
#  id         :integer          not null, primary key
#  shop_id    :integer
#  last_name  :string
#  first_name :string
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Customer < ApplicationRecord
  default_value_for :state, "normal"
  STATES = %w(vip normal)

  validates :state, inclusion: { in: STATES }
  belongs_to :shop

  def name
    "#{last_name} #{first_name}"
  end
end
