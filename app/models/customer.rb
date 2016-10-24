# == Schema Information
#
# Table name: customers
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  contact_group_id         :integer
#  last_name                :string
#  first_name               :string
#  phonetic_last_name       :string
#  phonetic_first_name      :string
#  address                  :string
#  google_uid               :string
#  google_contact_id        :string
#  google_contact_group_ids :string           default([]), is an Array
#  birthday                 :date
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class Customer < ApplicationRecord
  default_value_for :last_name, ""
  default_value_for :first_name, ""
  default_value_for :phonetic_last_name, ""
  default_value_for :phonetic_first_name, ""
  attr_accessor :emails
  attr_accessor :phone_numbers

  belongs_to :user
  belongs_to :contact_group

  validates :google_contact_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true

  def name
    "#{phonetic_last_name} #{phonetic_first_name}".presence || "#{first_name} #{last_name} "
  end
end
