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
#  custom_id                :string
#  memo                     :text
#  address                  :string
#  google_uid               :string
#  google_contact_id        :string
#  google_contact_group_ids :string           default([]), is an Array
#  birthday                 :date
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#

class Customer < ApplicationRecord
  include NormalizeName

  attr_accessor :emails, :phone_numbers, :addresses, :primary_email, :primary_address, :primary_phone, :dob, :other_addresses

  has_many :reservation_customers, dependent: :destroy
  has_many :reservations, through: :reservation_customers
  belongs_to :user
  belongs_to :updated_by_user, class_name: "User"
  belongs_to :contact_group
  belongs_to :rank

  validates :google_contact_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true

  before_validation :assign_default_rank

  def build_by_google_contact(google_contact)
    self.google_uid = user.uid
    self.first_name = google_contact.first_name || first_name
    self.last_name = google_contact.last_name || last_name
    self.phonetic_last_name = google_contact.phonetic_last_name || phonetic_last_name
    self.phonetic_first_name = google_contact.phonetic_first_name || phonetic_first_name
    self.google_contact_group_ids = google_contact.group_ids
    self.birthday = Date.parse(google_contact.birthday) if google_contact.birthday
    self.addresses = google_contact.addresses
    self.primary_address = primary_value(google_contact.addresses)
    self.other_addresses = (self.addresses - [self.primary_address]).map(&:to_h)
    self.address = primary_part_address(google_contact.addresses)
    self.emails = google_contact.emails
    self.phone_numbers = google_contact.phone_numbers
    self.primary_email = google_contact.primary_email
    self.primary_phone = primary_value(google_contact.phone_numbers)
    self
  end

  def display_address
    if primary_address && primary_address["value"].present?
      _address = primary_formatted_address
      postcode = [_address.value.postcode1.presence, _address.value.postcode2.presence].compact.join("-")

      zipcode = if postcode.present?
                  "〒#{postcode} "
                end

      "#{zipcode}#{_address.value.region}#{_address.value.city}#{_address.value.street1}#{_address.value.street2}"
    else
      address
    end
  end

  def primary_formatted_address
    @primary_formatted_address ||= Hashie::Mash.new(primary_address).tap do |address|
      address.value.postcode1 = address.value.postcode ? address.value.postcode.first(3) : ""
      address.value.postcode2 = address.value.postcode ? address.value.postcode[3..-1] : ""
      streets = address.value.street ? address.value.street.split(",") : []
      address.value.street1 = streets.first
      address.value.street2 = streets[1..-1].try(:join, ",")
    end
  end

  def google_contact_attributes(google_groups_changes={})
    h = {
      name: { familyName: last_name, givenName: first_name},
      phonetic_name: { familyName: phonetic_last_name, givenName: phonetic_first_name},
      emails: Array.wrap(emails),
      phone_numbers: Array.wrap(phone_numbers),
      addresses: Array.wrap(addresses),
    }.merge(google_groups_changes || {})

    h.merge!(birthday: birthday.try(:to_s)) if birthday
    h.with_indifferent_access
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
      [address.value.region, address.value.city].compact.join(" ")
    end
  end

  def assign_default_rank
    self.rank ||= contact_group.ranks.find_by(key: Rank::REGULAR_KEY)
  end
end
