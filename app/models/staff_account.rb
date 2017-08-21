# == Schema Information
#
# Table name: staff_accounts
#
#  id         :integer          not null, primary key
#  email      :string           not null
#  user_id    :integer
#  owner_id   :integer          not null
#  staff_id   :integer          not null
#  token      :string
#  state      :integer          default("pending"), not null
#  level      :integer          default("staff"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class StaffAccount < ApplicationRecord
  enum state: {
    pending: 0,
    active: 1,
    disabled: 2
  }

  enum level: {
    staff: 0,
    manager: 1
  }

  belongs_to :staff
  belongs_to :user
  belongs_to :owner, class_name: "User"

  validates :owner_id, presence: true
  validates :staff_id, presence: true, uniqueness: { scope: :owner_id }
end
