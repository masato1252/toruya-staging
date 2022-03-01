# == Schema Information
#
# Table name: online_service_customer_relations
#
#  id                     :bigint           not null, primary key
#  current                :boolean          default(TRUE)
#  expire_at              :datetime
#  paid_at                :datetime
#  payment_state          :integer          default("pending"), not null
#  permission_state       :integer          default("pending"), not null
#  product_details        :json
#  watched_lesson_ids     :string           default([]), is an Array
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  customer_id            :integer          not null
#  online_service_id      :integer          not null
#  sale_page_id           :integer          not null
#  stripe_subscription_id :string
#
# Indexes
#
#  online_service_relation_index         (online_service_id,customer_id,permission_state)
#  online_service_relation_unique_index  (online_service_id,customer_id,current) UNIQUE
#
# product_details: {
#   prices: [
#     {
#       amount: 1000,
#       charge_date: Time.current.to_s, => scheduled job date
#       order_id: XXXX => used by customer_payment order_id
#     },
#     ...
#   ]
# }

class OnlineServiceCustomerRelation < ApplicationRecord
  ACTIVE_STATES = %w[pending free paid partial_paid].freeze

  include SayHi
  hi_track_event "online_service_purchased"

  has_many :customer_payments, as: :product
  has_one :last_customer_payment, -> { order(id: :desc) } , as: :product, class_name: "CustomerPayment"
  belongs_to :online_service
  belongs_to :sale_page
  belongs_to :customer

  scope :available, -> { active.current.where("expire_at is NULL or expire_at >= ?", Time.current) }
  scope :uncanceled, -> { where.not(payment_state: :canceled) }
  scope :current, -> { where(current: true) }

  enum payment_state: {
    pending: 0,
    free: 1,
    paid: 2,
    failed: 3,
    refunded: 4,
    canceled: 5,
    partial_paid: 6
  }, _suffix: true

  enum permission_state: {
    pending: 0,
    active: 1
  }

  def approved_at
    active_at if active?
  end

  def active_at
    paid_at || created_at
  end

  def start_date_text
    I18n.l(online_service.start_at || active_at, format: :long_date)
  end

  def end_date_text
    if expire_at
      I18n.l(expire_at, format: :long_date)
    else
      I18n.t("sales.never_expire")
    end
  end

  def available?
    state == "available"
  end

  def inactive?
    state == "inactive"
  end

  def state
    return "inactive" if ACTIVE_STATES.exclude?(payment_state) || (active? && expire_at && expire_at < Time.current)
    return "pending" if pending?
    "available"
  end

  def purchased?
    free_payment_state? || paid_payment_state? || partial_paid_payment_state?
  end

  def hi_message
    "🖥 New online_service purchased, id: #{id}, online_service: #{online_service.slug}, sale_page: #{sale_page.slug}, customer_id: #{customer_id}, user_id: #{customer.user_id}, payment_state: #{payment_state}, permission_state: #{permission_state}, expire_at: #{expire_at ? I18n.l(expire_at, format: :long_date_with_wday) : ""}"
  end

  def price_details
    product_details["prices"].map do |_attributes|
      ::OnlineServiceCustomerPrice.new(_attributes.merge(
        charge_at: _attributes["charge_at"] ? Time.parse(_attributes["charge_at"]) : nil
      ))
    end
  end

  def total_completed_payments_amount
    customer_payments.completed.sum(&:amount)
  end

  def product_amount
    price_details.sum { |price| Money.new(price.amount) }
  end

  def paid_completed?
    total_completed_payments_amount >= product_amount
  end

  def selling_prices_text
    if free_payment_state?
      I18n.t("common.free_price")
    elsif price_details.size == 1
      price_details.first.amount.format(:ja_default_format)
    else
      times = price_details.size
      amount = price_details.first.amount

      "#{Money.new(amount).format(:ja_default_format)} X #{times} #{I18n.t("common.times")}"
    end
  end
end
