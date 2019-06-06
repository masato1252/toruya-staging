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
#  updated_by_user_id       :integer
#  email_types              :string
#  deleted_at               :datetime
#
# Indexes
#
#  customer_names_on_first_name_idx           (first_name) USING gin
#  customer_names_on_last_name_idx            (last_name) USING gin
#  customer_names_on_phonetic_first_name_idx  (phonetic_first_name) USING gin
#  customer_names_on_phonetic_last_name_idx   (phonetic_last_name) USING gin
#  customers_basic_index                      (user_id,contact_group_id,deleted_at)
#  customers_google_index                     (user_id,google_uid,google_contact_id) UNIQUE
#  jp_name_index                              (user_id,phonetic_last_name,phonetic_first_name)
#

class Customer < ApplicationRecord
  include NormalizeName

  attr_accessor :emails, :phone_numbers, :addresses, :primary_email, :primary_address, :primary_phone, :dob, :other_addresses, :google_down, :google_contact_missing

  has_many :reservation_customers
  has_many :reservations, -> { active }, through: :reservation_customers
  belongs_to :user
  belongs_to :updated_by_user, class_name: "User", required: false
  belongs_to :contact_group, required: false
  belongs_to :rank, required: false

  validates :google_contact_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true

  before_validation :assign_default_rank

  scope :jp_chars_order, -> { order(Arel.sql('phonetic_last_name COLLATE "C" ASC')) }
  scope :active, -> { where(deleted_at: nil) }
  scope :contact_groups_scope, ->(staff) { where(contact_group_id: staff.readable_contact_group_ids) }

  def with_google_contact
    @customer_with_google_contact ||=
      if google_contact_id
        build_by_google_contact(Customers::RetrieveGoogleContact.run!(customer: self))
      else
        self
      end
  end

  def build_by_google_contact(google_contact)
    # Fetch from google fail
    if google_contact.is_a?(Customer)
      return self
    end

    # XXX: Below means contact was deleted in google contacts
    if google_contact.first_name.nil? && google_contact.last_name.nil? && google_contact.phonetic_first_name.nil? && google_contact.phonetic_last_name.nil?
      self.google_contact_missing = true
    end

    self.google_uid = user.uid
    self.first_name = google_contact.first_name || first_name
    self.last_name = google_contact.last_name || last_name
    self.phonetic_last_name = google_contact.phonetic_last_name || phonetic_last_name
    self.phonetic_first_name = google_contact.phonetic_first_name || phonetic_first_name
    self.google_contact_group_ids = google_contact.group_ids
    self.birthday = Date.parse(google_contact.birthday) if google_contact.birthday
    self.addresses = google_contact.addresses || []
    # primary_address format
    # {
    #   type: "home",
    #   value: {
    #     formatted_address: "4F.-3, No.125, Sinsing St\nTainan, 岩手県 7107108"
    #     primary: true
    #     postcode: "7107108"
    #     city: "Tainan"
    #     region: "岩手県"
    #     street: "4F.-3, No.125, Sinsing St"
    #   }
    # }
    self.primary_address = primary_value(google_contact.addresses)
    self.other_addresses = (self.addresses - [self.primary_address]).map(&:to_h)
    self.address = primary_part_address(google_contact.addresses)
    # emails format
    # [
    #   {
    #     "type" => :home,
    #     "value" => {
    #       "address" => "lake.ilakela@gmail.com",
    #       "primary" => true,
    #       "label" => "home"
    #     }
    #   }
    # ]
    self.emails = google_contact.emails
    # phone_numbers format
    # [
    #   {
    #     "type" => :home,
    #     "value" => "12312312"
    #   }
    # ]
    self.phone_numbers = google_contact.phone_numbers
    # primary_email format:
    # {
    #   address: "lake.ilakela@gmail.com",
    #   primary: true,
    #   label: "home"
    # }
    self.primary_email = google_contact.primary_email
    # primary_phone format
    # {
    #   "type" => :home,
    #   "value" => "12312312"
    # }
    self.primary_phone = primary_value(google_contact.phone_numbers)
    self
  end

  def display_address
    if primary_address && primary_address["value"].present?
      _address = primary_formatted_address

      "#{zipcode}#{_address.value.region}#{_address.value.city}#{_address.value.street1}#{_address.value.street2}"
    else
      address
    end
  end

  def zipcode
    if primary_address && primary_address["value"].present?
      _address = primary_formatted_address
      postcode = [_address.value.postcode1.presence, _address.value.postcode2.presence].compact.join("-")

      zipcode = if postcode.present?
                  "〒#{postcode} "
                end
    end
  end

  def primary_formatted_address
    return unless primary_address

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
