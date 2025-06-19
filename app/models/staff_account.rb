# frozen_string_literal: true

# == Schema Information
#
# Table name: staff_accounts
#
#  id                :integer          not null, primary key
#  email             :string
#  user_id           :integer
#  owner_id          :integer          not null
#  staff_id          :integer          not null
#  token             :string
#  state             :integer          default("pending"), not null
#  level             :integer          default("employee"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  active_uniqueness :boolean
#  phone_number      :string
#
# Indexes
#
#  index_staff_accounts_on_owner_id_and_phone_number  (owner_id,phone_number) UNIQUE
#  index_staff_accounts_on_staff_id                   (staff_id)
#  index_staff_accounts_on_user_id                    (user_id)
#  staff_account_email_index                          (owner_id,email)
#  staff_account_token_index                          (token)
#  unique_staff_account_index                         (owner_id,user_id,active_uniqueness) UNIQUE
#

class StaffAccount < ApplicationRecord
  enum state: {
    pending: 0,
    active: 1,
    disabled: 2
  }

  enum level: {
    employee: 0,
    owner: 1,
    admin: 2
  }

  belongs_to :staff
  belongs_to :user, required: false # before staff account active, it won't connect with a user.
  belongs_to :owner, class_name: "User"

  validates :owner_id, presence: true
  validates :staff_id, presence: true, uniqueness: { scope: [:owner_id] }
  validates :phone_number, uniqueness: { scope: [:owner_id] }, if: -> (staff_account) { staff_account.phone_number.present? }
  validates :email, uniqueness: { scope: [:owner_id] }, if: -> (staff_account) { staff_account.email.present? }
  validates :user_id, uniqueness: { scope: [:owner_id, :active_uniqueness] }, if: -> (staff_account) { staff_account.active_uniqueness.present? }
  scope :visible, -> { where("staff_accounts.user_id = staff_accounts.owner_id").or(where.not(level: "owner")) }

  def mark_active
    self.state = :active
    self.active_uniqueness = true
  end

  def mark_pending
    self.state = :pending
    self.active_uniqueness = nil
  end

  def locale
    owner.locale
  end
end
