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
# Indexes
#
#  index_staff_accounts_on_owner_id  (owner_id)
#  index_staff_accounts_on_staff_id  (staff_id)
#  index_staff_accounts_on_user_id   (user_id)
#  staff_account_email_index         (owner_id,email)
#  staff_account_index               (owner_id,user_id)
#  staff_account_token_index         (token)
#

class StaffAccount < ApplicationRecord
  enum state: {
    pending: 0,
    active: 1,
    disabled: 2
  }

  enum level: {
    staff: 0,
    manager: 1,
    owner: 2
  }

  belongs_to :staff
  belongs_to :user, required: false # before staff account active, it won't connect with a user.
  belongs_to :owner, class_name: "User"

  validates :owner_id, presence: true
  validates :staff_id, presence: true, uniqueness: { scope: [:owner_id] }
  validates :user_id, uniqueness: { scope: [:owner_id] }, allow_nil: true,  if: -> { state == "active" }, on: :create
end
