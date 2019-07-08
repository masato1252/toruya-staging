# == Schema Information
#
# Table name: reservation_customers
#
#  id                      :integer          not null, primary key
#  reservation_id          :integer          not null
#  customer_id             :integer          not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  booking_page_id         :integer
#  booking_option_id       :integer
#  state                   :integer          default("pending")
#  booking_amount_currency :string
#  booking_amount_cents    :decimal(, )
#  tax_include             :boolean
#  booking_at              :datetime
#  details                 :jsonb
#
# Indexes
#
#  index_reservation_customers_on_reservation_id_and_customer_id  (reservation_id,customer_id) UNIQUE
#

require "hashie_serializer"

class ReservationCustomer < ApplicationRecord
  belongs_to :reservation
  belongs_to :customer, touch: true
  belongs_to :booking_page, required: false
  belongs_to :booking_option, required: false
  serialize :details, HashieSerializer

  enum state: {
    pending: 0,
    accepted: 1,
    canceled: 2,
  }

  monetize :booking_amount_cents, allow_nil: true

  scope :active, -> { where.not(state: :canceled) }

  def customer_info
    CustomerInfo.new(details.new_customer_info)
  end
end
