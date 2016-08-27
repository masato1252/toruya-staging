# == Schema Information
#
# Table name: customers
#
#  id            :integer          not null, primary key
#  shop_id       :integer
#  last_name     :string
#  first_name    :string
#  jp_last_name  :string
#  jp_first_name :string
#  state         :string
#  phone_number  :string
#  phone_type    :string
#  birthday      :date
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Customer < ApplicationRecord
  default_value_for :state, "normal"
  default_value_for :last_name, ""
  default_value_for :first_name, ""
  default_value_for :jp_last_name, ""
  default_value_for :jp_first_name, ""
  default_value_for :phone_number, ""
  default_value_for :phone_type, "mobile"

  STATES = %w(vip normal)
  PHONE_TYPES = %w(mobile home)

  validates :state, inclusion: { in: STATES }
  validates :phone_type, inclusion: { in: PHONE_TYPES }
  belongs_to :shop

  def name
    "#{jp_last_name} #{jp_first_name}".presence || "#{first_name} #{last_name} "
  end
end
