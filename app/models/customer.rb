# == Schema Information
#
# Table name: customers
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  contact_group_id         :integer
#  rank_id                  :integer
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
  RANKING_COLORS = %s(ca4e0e d0d0d0 60938a fcbe46 aecfc8)

  default_value_for :last_name, ""
  default_value_for :first_name, ""
  default_value_for :phonetic_last_name, ""
  default_value_for :phonetic_first_name, ""
  attr_accessor :emails, :phone_numbers, :addresses, :primary_email, :primary_address, :primary_phone

  belongs_to :user
  belongs_to :contact_group

  validates :google_contact_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true

  def name
    "#{phonetic_last_name} #{phonetic_first_name}".presence || "#{first_name} #{last_name} "
  end

  def build_by_google_contact(google_contact)
    self.google_uid = user.uid
    self.first_name = google_contact.first_name
    self.last_name = google_contact.last_name
    self.phonetic_last_name = google_contact.phonetic_last_name
    self.phonetic_first_name = google_contact.phonetic_first_name
    self.google_contact_group_ids = google_contact.group_ids
    self.birthday = Date.parse(google_contact.birthday) if google_contact.birthday
    self.primary_address = primary_value(google_contact.addresses)
    self.address = primary_part_address(google_contact.addresses)
    self.addresses = google_contact.addresses
    self.emails = google_contact.emails
    self.phone_numbers = google_contact.phone_numbers
    self.primary_email = google_contact.primary_email
    self.primary_phone = primary_value(google_contact.phone_numbers)
    self
  end

  def display_address
    (primary_address && primary_address.value.formatted_address) || address
  end

  private

  def primary_value(values)
    return unless values

    values.find { |h| h.value.respond_to?(:primary) && h.value.primary } ||
      values.find { |h| h.type == :mobile } ||
      values.find { |h| h.type == :home } ||
      values.find { |h| h.type == :work } ||
      values.first
  end

  def primary_part_address(addresses)
    return unless addresses

    address = primary_value(addresses)
    if address && (address.value.city || address.value.region)
      "#{address.value.city},#{address.value.region}"
    end
  end
end
