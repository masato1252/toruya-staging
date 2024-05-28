# == Schema Information
#
# Table name: consultant_accounts
#
#  id                 :bigint           not null, primary key
#  phone_number       :string           not null
#  state              :integer          default("pending"), not null
#  token              :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  consultant_user_id :bigint           not null
#
# Indexes
#
#  consultant_account_phone_index                   (consultant_user_id,phone_number) UNIQUE
#  consultant_account_token_index                   (token) UNIQUE
#  index_consultant_accounts_on_consultant_user_id  (consultant_user_id)
#
class ConsultantAccount < ApplicationRecord
  belongs_to :consultant_user, class_name: "User"
  validates :phone_number, uniqueness: { scope: [:consultant_user_id] }

  enum state: {
    pending: 0,
    active: 1
  }
end
