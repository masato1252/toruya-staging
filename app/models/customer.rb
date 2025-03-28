# frozen_string_literal: true
# == Schema Information
#
# Table name: customers
#
#  id                           :integer          not null, primary key
#  address                      :string
#  address_details              :jsonb
#  birthday                     :date
#  customer_email               :string
#  customer_phone_number        :string
#  deleted_at                   :datetime
#  email_types                  :string
#  emails_details               :jsonb
#  first_name                   :string
#  google_contact_group_ids     :string           default([]), is an Array
#  google_uid                   :string
#  last_name                    :string
#  memo                         :text
#  menu_ids                     :string           default([]), is an Array
#  mixpanel_profile_last_set_at :datetime
#  online_service_ids           :string           default([]), is an Array
#  phone_numbers_details        :jsonb
#  phonetic_first_name          :string
#  phonetic_last_name           :string
#  reminder_permission          :boolean          default(TRUE)
#  tags                         :string           default([]), is an Array
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  contact_group_id             :integer
#  custom_id                    :string
#  google_contact_id            :string
#  rank_id                      :integer
#  square_customer_id           :string
#  stripe_customer_id           :string
#  updated_by_user_id           :integer
#  user_id                      :integer          not null
#
# Indexes
#
#  customer_names_on_first_name_idx                      (first_name) USING gin
#  customer_names_on_last_name_idx                       (last_name) USING gin
#  customer_names_on_phonetic_first_name_idx             (phonetic_first_name) USING gin
#  customer_names_on_phonetic_last_name_idx              (phonetic_last_name) USING gin
#  customers_basic_index                                 (user_id,contact_group_id,deleted_at)
#  customers_google_index                                (user_id,google_uid,google_contact_id) UNIQUE
#  index_customers_on_user_id_and_customer_email         (user_id,customer_email)
#  index_customers_on_user_id_and_customer_phone_number  (user_id,customer_phone_number) UNIQUE
#  jp_name_index                                         (user_id,phonetic_last_name,phonetic_first_name)
#  used_services_index                                   (user_id,menu_ids,online_service_ids) USING gin
#

# attributes format:
#
# phone_numbers_details: [{"type" => "mobile", "value" => "1234567"}]
# email_details: [{"type" => "mobile", "value" => "email@email.com"}]
# address_details: {
#   zip_code: "zip_code",
#   region: "region",
#   city: "city"
#   street1: "street1"
#   street2: "street2"
# }

class Customer < ApplicationRecord
  has_paper_trail on: [:update]
  BLACKLIST_IDS = [6388]
  include NormalizeName
  include SayHi

  DASHBOARD_TARGET_VIEWS = {
    reservations: "customer_reservations",
    messages: "customer_messages",
    payments: "customer_payments"
  }

  attr_accessor :emails, :phone_numbers, :addresses, :primary_email, :primary_address, :primary_phone, :dob, :other_addresses, :google_down, :google_contact_missing

  has_one :social_customer, -> { order(id: :desc) }
  has_many :social_customers
  has_many :reservation_customers
  has_many :reservations, -> { active }, through: :reservation_customers
  has_many :customer_payments
  has_many :online_service_customer_relations, -> { available }
  has_many :online_service_customer_applications, class_name: "OnlineServiceCustomerRelation", foreign_key: :customer_id
  has_many :customer_tickets
  belongs_to :user, counter_cache: true
  belongs_to :updated_by_user, class_name: "User", required: false
  belongs_to :contact_group, required: false
  belongs_to :rank, required: false

  validates :google_contact_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true
  validates :customer_phone_number, uniqueness: { scope: [:user_id] }, allow_nil: true

  before_validation :assign_default_rank

  scope :jp_chars_order, -> { order(Arel.sql('phonetic_last_name COLLATE "C" ASC')) }
  scope :active, -> { where(deleted_at: nil) }
  scope :active_in, ->(time_ago) { active.where("customers.updated_at > ?", time_ago) }
  scope :contact_groups_scope, ->(staff) { where(contact_group_id: staff.readable_contact_group_ids) }
  scope :marketable, -> { where(reminder_permission: true) }

  before_validation :update_customer_email_and_phone_number

  def update_customer_email_and_phone_number
    self.customer_email = email
    self.customer_phone_number = Phonelib.parse(mobile_phone_number).international(false)
  end

  def active_customer_ticket_of_product(product) # booking_option
    customer_tickets.active.unexpired.joins(ticket: :ticket_products).where("ticket_products.product": product).take
  end

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
    # ===
    # XXX:
    # The format read and write emails in customer is different
    #
    # [Read]
    # customer.emails
    #
    # [
    #   {
    #     "type" => :mobile,
    #     "value" => {
    #       "address" => "lake.ilakela@gmail.com",
    #       "primary" => true,
    #       "label" => "mobile"
    #     },
    #     "primary" => true
    #   }
    # ]
    #
    # [Write]
    # customer.emails = new_emails
    #
    # [
    #   {
    #     "type"=> "mobile",
    #     "value"=> {
    #       "address" => "lake.ilakela@gmail.com4"
    #     },
    #     "primary"=>true
    #   }
    # ]
    # XXX:
    # The format read and write addresses in customer is different
    #
    # [Read]
    # customer.phone_numbers
    # [
    #   {
    #     "type" => :home,
    #     "value" => "12312312",
    #     "primary" => true
    #   }
    # ]
    #
    # [Write]
    # customer.phone_numbers = new_phone_numbers
    #
    # [
    #   {
    #     "type"=> "mobile",
    #     "value"=> "12312312",
    #     "primary" => true
    #   }
    # ]
    # XXX:
    # The format read and write addresses in customer is different
    #
    # [Read]
    # customer.addresses
    #
    # [
    #   {
    #     "primary" => true,
    #     "type" => :home,
    #     "value" => {
    #       "primary" => true,
    #       "formatted_address" => "4F.-3, No.125, Sinsing StTainan\n岩手県",
    #       "street" => "4F.-3, No.125, Sinsing StTainan",
    #       "region" => "岩手県"
    #     }
    #   }
    # ]
    #
    # [Write]
    # customer.addresses = new_addresses
    #
    # [
    #   {
    #     "primary" => true,
    #     "type" => "home",
    #     "value" => {
    #       "postcode" => "",
    #       "region" => "岩手県",
    #       "city" => "",
    #       "street" => "4F.-3, No.125, Sinsing StTainan"
    #     },
    #   }
    # ]
    # ===
    self.emails = google_contact.emails
    self.phone_numbers = google_contact.phone_numbers
    # primary_email format:
    # {
    #   "primary" => true,
    #   "type" => :mobile,
    #   "value" => {
    #     "address" => "lake.ilakela@gmail.com5",
    #     "primary" => true,
    #     "label" => "mobile"
    #   }
    # }
    self.primary_email = google_contact.primary_email
    # primary_phone format
    # {
    #   "primary" => true
    #   "type" => :home,
    #   "value" => "12312312"
    # }
    self.primary_phone = primary_value(google_contact.phone_numbers)
    self
  end

  # def display_address
  #   if primary_address && primary_address["value"].present?
  #     _address = primary_formatted_address
  #
  #     "#{zipcode}#{_address.value.region}#{_address.value.city}#{_address.value.street1}#{_address.value.street2}"
  #   else
  #     address
  #   end
  # end

  def display_address
    if address_details.present?
      "#{address_details["zip_code"]}#{address_details["region"]}#{address_details["city"]}#{address_details["street1"]}#{address_details["street2"]}"
    end
  end

  # def zipcode
  #   if primary_address && primary_address["value"].present?
  #     _address = primary_formatted_address
  #     postcode = [_address.value.postcode1.presence, _address.value.postcode2.presence].compact.join("-")
  #
  #     zipcode = if postcode.present?
  #                 "〒#{postcode} "
  #               end
  #   end
  # end
  def zipcode
    if postcode = address_details.dig("zip_code")

      if postcode.present?
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
    # [Write]
    # customer.phone_numbers = new_phone_numbers
    #
    # [
    #   {
    #     "type"=> "mobile",
    #     "value"=> "12312312",
    #     "primary" => true
    #   }
    # ]
    #
    # [Write]
    # customer.emails = new_emails
    #
    # [
    #   {
    #     "type"=> "mobile",
    #     "value"=> {
    #       "address" => "lake.ilakela@gmail.com4"
    #     },
    #     "primary"=>true
    #   }
    # ]
    #
    # [Write]
    # customer.addresses = new_addresses
    #
    # [
    #   {
    #     "type" => "home",
    #     "value" => {
    #       "postcode" => "",
    #       "region" => "岩手県",
    #       "city" => "",
    #       "street" => "4F.-3, No.125, Sinsing StTainan"
    #     },
    #     "primary" => true
    #   }
    # ]
    #
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

  def main_email
    emails_details&.find { |email| email["value"].present? }
  end

  def main_phone
    phone_numbers_details&.first
  end

  def email
    main_email&.dig("value")
  end

  def phone_number
    (main_mobile_phone || main_phone)&.dig("value")
  end

  def mobile_phone_number
    main_mobile_phone&.dig("value")
  end

  def main_mobile_phone
    phone_numbers_details&.find{|h| h["type"] == "mobile" && h["value"].present?}
  end

  def simple_address
    if address_details.present?
      [address_details["region"], address_details["city"]].compact.join(" ")
    end
  end

  def hi_message
    "👩 New customer joined, customer_id: #{id}, user_id: #{user_id}, customers count: #{user.customers.size}"
  end

  def had_address?
    Address.new(address_details).exists?
  end

  def in_blacklist?
    BLACKLIST_IDS.include?(id)
  end

  def locale
    user.locale
  end

  def timezone
    user.timezone
  end

  private

  def primary_value(values)
    return unless values

    values.find { |h| h.try(:primary) } ||
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
    self.rank ||= contact_group&.ranks&.find_by(key: Rank::REGULAR_KEY)
  end
end
