# == Schema Information
#
# Table name: profiles
#
#  id                  :integer          not null, primary key
#  user_id             :integer
#  first_name          :string
#  last_name           :string
#  phonetic_first_name :string
#  phonetic_last_name  :string
#  company_name        :string
#  zip_code            :string
#  address             :string
#  phone_number        :string
#  website             :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Profile < ApplicationRecord
  include NormalizeName

  belongs_to :user

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phonetic_first_name, presence: true
  validates :phonetic_last_name, presence: true
  validates :company_name, presence: true
  validates :zip_code, presence: true
  validates :address, presence: true
end
