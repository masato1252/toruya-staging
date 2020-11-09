# == Schema Information
#
# Table name: profiles
#
#  id                   :integer          not null, primary key
#  user_id              :integer
#  first_name           :string
#  last_name            :string
#  phonetic_first_name  :string
#  phonetic_last_name   :string
#  company_name         :string
#  zip_code             :string
#  address              :string
#  phone_number         :string
#  website              :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  company_zip_code     :string
#  company_address      :string
#  company_phone_number :string
#  email                :string
#  region               :string
#  city                 :string
#  street1              :string
#  street2              :string
#
# Indexes
#
#  index_profiles_on_user_id  (user_id)
#

class Profile < ApplicationRecord
  include NormalizeName

  belongs_to :user

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phonetic_first_name, presence: true
  validates :phonetic_last_name, presence: true

  def personal_full_address
    "〒#{zip_code} #{address}" if address.present?
  end

  def company_full_address
    "〒#{company_zip_code} #{company_address}" if company_address.present?
  end
end
