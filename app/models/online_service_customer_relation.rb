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
#  bundled_service_id     :integer
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

class OnlineServiceCustomerRelation < ApplicationRecord
  ACTIVE_STATES = %w[pending free paid partial_paid].freeze

  include SayHi
  hi_track_event "online_service_purchased"
  has_paper_trail on: [:update], only: [:payment_state, :permission_state, :product_details, :sale_page_id]

  alias_attribute :watched_episode_ids, :watched_lesson_ids

  has_many :customer_payments, as: :product
  has_one :last_customer_payment, -> { order(id: :desc) } , as: :product, class_name: "CustomerPayment"
  belongs_to :online_service
  belongs_to :sale_page
  belongs_to :customer
  belongs_to :bundled_service, optional: true

  # Don't add this scope, where("online_services.start_at is NULL or online_services.start_at < :now", now: Time.current)
  # because we need to a scope to filter the relations is legal to send them messages or do something even before service started
  # So this scope couldn't guarantee customer could start to use service since it doesn't check service start time
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

  def accessible?
    state == "accessible"
  end

  def available?
    state == "available"
  end

  def inactive?
    state == "inactive" # equal !legal_to_access?
  end

  # available means you are legal to use, but the service doesn't start yet
  def state
    return "accessible" if payment_legal_to_access? && active? && service_started?
    return "available" if payment_legal_to_access? && active? && !service_started?
    return "pending" if payment_legal_to_access? && pending?
    "inactive"
  end

  def legal_to_access?
    payment_legal_to_access? && active?
  end

  def payment_legal_to_access? # payment is fine
    @payment_legal_to_access ||= current && ACTIVE_STATES.include?(payment_state) && unexpired?
  end

  def service_started?
    (online_service.start_at.nil? || online_service.start_at < Time.current)
  end

  def unexpired?
    expire_at.nil? || expire_at >= Time.current
  end

  def purchased?
    free_payment_state? || paid_payment_state? || partial_paid_payment_state?
  end

  def hi_message
    "🖥 New online_service purchased, id: #{id}, online_service: #{online_service.slug}, sale_page: #{sale_page.slug}, customer_id: #{customer_id}, user_id: #{customer.user_id}, payment_state: #{payment_state}, permission_state: #{permission_state}, expire_at: #{expire_at ? I18n.l(expire_at, format: :long_date_with_wday) : ""}"
  end

  def price_details
    product_details["prices"].map do |_attributes|
      if _attributes["bundler_price"]
        bundler_relation.price_details.first
      else
        ::OnlineServiceCustomerPrice.new(_attributes.merge(
          charge_at: _attributes["charge_at"] ? Time.parse(_attributes["charge_at"]) : nil
        ))
      end
    end
  end

  def bundler_relation
    @bundler_relation ||= OnlineServiceCustomerRelation.where(
      online_service: sale_page.product,
      sale_page: sale_page,
      customer: customer,
    ).where.not(id: id).take
  end

  def bundled_service_relations
    # TODO: might need bundled_service_id
    @bundled_service_relations ||= OnlineServiceCustomerRelation.where(
      online_service: sale_page.product.bundled_online_services,
      sale_page: sale_page,
      customer: customer
    )
  end

  def purchased_from_bundler?
    product_details["prices"].first["bundler_price"]
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

  def order_completed
    @order_completed ||= customer_payments.order("id DESC").each_with_object({}) do |payment, h|
      next if h[payment.order_id] == true

      h[payment.order_id] = payment.completed?
    end
  end

  def selling_prices_text
    if purchased_from_bundler?
      bundler_relation.selling_prices_text
    else
      if free_payment_state?
        I18n.t("common.free_price")
      elsif price_details.first.interval
        # month_pay, year_pay
        "#{I18n.t("common.#{price_details.first.interval}_pay")} #{price_details.first.amount_with_currency.format(:ja_default_format)}"
      elsif online_service.external?
        I18n.t("common.contact_owner_directly")
      elsif price_details.size == 1
        "#{I18n.t("common.one_time_pay")} #{price_details.first.amount_with_currency.format(:ja_default_format)}"
      else
        times = price_details.size
        amount_with_currency = price_details.first.amount_with_currency

        "#{I18n.t("common.multiple_times_pay")} #{amount_with_currency.format(:ja_default_format)} X #{times} #{I18n.t("common.times")}"
      end
    end
  end
end
