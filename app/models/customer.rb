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
  attr_accessor :primary_email
  attr_accessor :primary_phone
  attr_accessor :addresses

  belongs_to :user
  belongs_to :contact_group

  validates :google_contact_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true

  def name
    "#{phonetic_last_name} #{phonetic_first_name}".presence || "#{first_name} #{last_name} "
  end

  def build_by_google_contact(google_contact, part_address=false)
    self.google_uid = user.uid
    self.first_name = google_contact.first_name
    self.last_name = google_contact.last_name
    self.phonetic_last_name = google_contact.phonetic_last_name
    self.phonetic_first_name = google_contact.phonetic_first_name
    self.google_contact_group_ids = google_contact.group_ids
    self.birthday = Date.parse(google_contact.birthday) if google_contact.birthday
    self.address = part_address ? primary_part_address(google_contact.addresses) : primary_value(google_contact.addresses)
    self.addresses = google_contact.addresses
    self.emails = google_contact.emails
    self.phone_numbers = google_contact.phone_numbers
    self.primary_email = google_contact.primary_email
    self.primary_phone = primary_value(google_contact.phone_numbers)
    self
  end

  private

  def primary_value(values)
    return unless values

    if primary_value = values.find { |value_type, value| value.respond_to?(:primary) && value.primary }
      primary_value
    elsif home_value = values.find { |value_type, value| value_type == "home" }
      home_value
    elsif work_value = values.find { |value_type, value| value_type == "work" }
      work_value
    else
      values.first
    end
  end

  def primary_part_address(addresses)
    return unless addresses

    address_type, address = primary_value(addresses)
    if address && (address.city || address.region)
      "#{address.city},#{address.region}"
    end
  end
end
