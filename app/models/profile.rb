# frozen_string_literal: true
# == Schema Information
#
# Table name: profiles
#
#  id                       :integer          not null, primary key
#  address                  :string
#  city                     :string
#  company_address          :string
#  company_address_details  :jsonb
#  company_name             :string
#  company_phone_number     :string
#  company_zip_code         :string
#  email                    :string
#  first_name               :string
#  last_name                :string
#  personal_address_details :jsonb
#  phone_number             :string
#  phonetic_first_name      :string
#  phonetic_last_name       :string
#  region                   :string
#  street1                  :string
#  street2                  :string
#  template_variables       :json
#  website                  :string
#  zip_code                 :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  user_id                  :integer
#
# Indexes
#
#  index_profiles_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Profile < ApplicationRecord
  include NormalizeName

  belongs_to :user

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phonetic_first_name, presence: true
  validates :phonetic_last_name, presence: true

  def personal_full_address
    if personal_address_details.present?
      Address.new(personal_address_details).display_address
    elsif address.present?
      "〒#{zip_code} #{address}"
    end
  end

  def company_full_address
    if company_address_details.present?
      Address.new(company_address_details).display_address
    elsif company_address.present?
      "〒#{company_zip_code} #{company_address}"
    end
  end

  def logo_url
  end
end
