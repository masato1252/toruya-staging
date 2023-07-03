# frozen_string_literal: true

# == Schema Information
#
# Table name: reservation_customers
#
#  id                      :integer          not null, primary key
#  booking_amount_cents    :decimal(, )
#  booking_amount_currency :string
#  booking_at              :datetime
#  details                 :jsonb
#  payment_state           :integer          default("pending")
#  state                   :integer          default("pending")
#  tax_include             :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  booking_option_id       :integer
#  booking_page_id         :integer
#  customer_id             :integer          not null
#  reservation_id          :integer          not null
#  sale_page_id            :integer
#
# Indexes
#
#  index_reservation_customers_on_reservation_id_and_customer_id  (reservation_id,customer_id) UNIQUE
#  index_reservation_customers_on_sale_page_id_and_created_at     (sale_page_id,created_at)
#

require "hashie_serializer"

class ReservationCustomer < ApplicationRecord
  ACTIVE_STATES = %w[pending accepted].freeze
  include SayHi
  hi_track_event "reservation_booked"

  belongs_to :reservation, touch: true
  belongs_to :customer, touch: true
  belongs_to :booking_page, required: false
  belongs_to :booking_option, required: false
  serialize :details, HashieSerializer

  enum state: {
    pending: 0,
    accepted: 1,
    canceled: 2,
    deleted: 3
  }

  enum payment_state: {
    pending: 0,
    paid: 1,
    refunded: 2
  }, _prefix: :payment

  monetize :booking_amount_cents, allow_nil: true

  scope :active, -> { where(state: ACTIVE_STATES) }

  def customer_data_changed?
    customer_data_changes.present?
  end

  # The data that customer request to changes
  def customer_data_changes
    if new_customer_info?
      changes_data = []

      customer_info.name_attributes.each do |changed_attr, value|
        if customer.public_send(changed_attr) != value
          changes_data << changed_attr.to_s
        end
      end

      if customer_info.phone_number && customer.phone_number != customer_info.phone_number
        changes_data << "phone_number"
      end

      if customer_info.email && customer.email != customer_info.email
        changes_data << "email"
      end

      if customer_info.sorted_address_details.present?
        customer_info.sorted_address_details.each do |attr, value|
          if customer.address_details&.dig(attr).presence != value
            changes_data << attr
          end
        end
      end

      changes_data
    end
  end

  def customer_info
    Booking::CustomerInfo.new(details.new_customer_info)
  end

  def display_changed_address
    if new_customer_info? && customer_info.sorted_address_details.present?
      address_details = customer_info.sorted_address_details

      zipcode = address_details.zip_code ? "〒#{address_details.zip_code.first(4)}-#{address_details.zip_code.last(3)}" : customer.zipcode
      region = address_details.region.presence || customer.address_details.dig("region")
      city = address_details.city.presence || customer.address_details.dig("city")
      street1 = address_details.street1.presence || customer.address_details.dig("street1")
      street2 = address_details.street2.presence || customer.address_details.dig("street2")

      "#{zipcode} #{region}#{city}#{street1}#{street2}"
    end
  end

  def new_customer_info?
    customer_info.attributes.compact.present?
  end

  def hi_message
    "🗓 New reservation updated, reservation_id: #{reservation_id}, customer_id: #{customer_id}, sale_page_id: #{sale_page_id}, booking_page_id: #{booking_page_id}, booking_option_id: #{booking_option_id}, user_id: #{customer.user_id}, state: #{state}, booking_at: #{booking_at ? I18n.l(booking_at, format: :long_date_with_wday) : ""}"
  end
end
