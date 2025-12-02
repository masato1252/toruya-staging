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
#  company_email            :string
#  company_name             :string
#  company_phone_number     :string
#  company_zip_code         :string
#  context                  :jsonb
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
  include MalwareScannable
  store :context, accessors: [:where_know_toruya, :what_main_problem], coder: JSON

  belongs_to :user

  has_one_attached :logo
  scan_attachment :logo

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :phonetic_first_name, presence: false
  validates :phonetic_last_name, presence: false

  def personal_full_address
    if personal_address_details.present? && personal_address_details.values.any?(&:present?)
      Address.new(personal_address_details).display_address
    elsif address.present?
      "〒#{zip_code} #{address}"
    end
  end

  def company_full_address
    # company_address_details is a jsonb column
    # it has the following keys: city, region, street1, street2, zip_code
    # if company_address_details is present, use it
    # if company_address_details is not present, use company_address and company_zip_code
    # {
    #   "city" => "",
    #   "region" => "",
    #   "street1" => "",
    #   "street2" => "",
    #   "zip_code" => ""
    # }   
    if company_address_details.present? && company_address_details.values.any?(&:present?)
      Address.new(company_address_details).display_address
    elsif company_address.present?
      "#{company_zip_code} #{company_address}"
    end
  end

  def logo_url
    ApplicationController.helpers.shop_logo_url(self, "260")
  end
end
