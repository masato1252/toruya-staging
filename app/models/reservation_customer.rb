# frozen_string_literal: true

# == Schema Information
#
# Table name: reservation_customers
#
#  id                      :integer          not null, primary key
#  booking_amount_cents    :decimal(, )
#  booking_amount_currency :string
#  booking_at              :datetime
#  booking_option_ids      :jsonb
#  cancel_reason           :string
#  customer_tickets_quota  :jsonb
#  details                 :jsonb
#  nth_quota               :integer
#  payment_state           :integer          default("pending")
#  slug                    :string
#  state                   :integer          default("pending")
#  tax_include             :boolean
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  booking_option_id       :integer
#  booking_page_id         :integer
#  customer_id             :integer          not null
#  customer_ticket_id      :integer
#  function_access_id      :bigint
#  reservation_id          :integer          not null
#  sale_page_id            :integer
#
# Indexes
#
#  index_reservation_customers_on_function_access_id              (function_access_id)
#  index_reservation_customers_on_reservation_id_and_customer_id  (reservation_id,customer_id) UNIQUE
#  index_reservation_customers_on_sale_page_id_and_created_at     (sale_page_id,created_at)
#  index_reservation_customers_on_slug                            (slug) UNIQUE
#

require "hashie_serializer"

# customer_tickets_quota is a hash, key is customer_ticket_id, value is nth_quota
# {
#   customer_ticket_id1 => {
#     nth_quota: nth_quota1,
#     product_id: product_id1
#   },
#   customer_ticket_id2 => {
#     nth_quota: nth_quota2,
#     product_id: product_id2
#   }
# }

class ReservationCustomer < ApplicationRecord
  include TicketProductConcern
  CANCEL_REASONS = %w[other_placeholder reschedule_reason no_longer_needed_reason].freeze
  ACTIVE_STATES = %w[pending accepted].freeze
  include SayHi
  include Price
  hi_track_event "reservation_booked"

  belongs_to :reservation, touch: true
  belongs_to :customer, touch: true
  belongs_to :booking_page, required: false
  belongs_to :booking_option, required: false
  serialize :customer_tickets_quota, HashieSerializer
  serialize :details, HashieSerializer
  alias_attribute :amount, :booking_amount

  enum state: {
    pending: 0,
    accepted: 1,
    canceled: 2,
    deleted: 3,
    customer_canceled: 4
  }

  enum payment_state: {
    pending: 0,
    paid: 1,
    refunded: 2
  }, _prefix: :payment

  monetize :booking_amount_cents, allow_nil: true

  scope :active, -> { where(state: ACTIVE_STATES) }

  def booking_options
    @booking_options ||= BookingOption.where(id: booking_option_ids)
  end

  def paid_payment
    @paid_payment ||= customer.customer_payments.completed.where(product: self).first
  end

  def reservation_state
    if accepted?
      reservation.aasm_state
    elsif customer_canceled? || deleted? || canceled?
      "canceled"
    else
      state
    end
  end

  def allow_customer_cancel?
    if booking_page&.customer_cancel_request
      (reservation.start_time.to_date >= Time.current.advance(days: booking_page.customer_cancel_request_before_day).to_date) && (pending? || accepted? && (reservation.pending? || reservation.reserved?))
    else
      false
    end
  end

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
    "🗓 New reservation updated, reservation_id: #{reservation_id}, customer_id: #{customer_id}, sale_page_id: #{sale_page_id}, booking_page_id: #{booking_page_id}, booking_option_id: #{booking_option_id}, user_id: #{customer.user_id}, state: #{state}, booking_at: #{booking_at ? I18n.l(booking_at, format: :long_date_with_wday) : ""} reservation_start_time: #{I18n.l(reservation.start_time, format: :long_date_with_wday)}"
  end

  # keywords: other_placeholder, reschedule_reason, no_longer_needed_reason
  def cancel_reasons
    cancel_reason.split(",").map do |reason|
      if CANCEL_REASONS.include?(reason)
        I18n.t("booking.cancel_modal.cancel_reasons.#{reason}")
      else
        reason
      end
    end
  end

  private
  def products
    booking_options
  end

  def product_ids
    booking_option_ids
  end
end