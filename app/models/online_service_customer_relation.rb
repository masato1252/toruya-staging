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
#  function_access_id     :bigint
#  online_service_id      :integer          not null
#  sale_page_id           :integer
#  stripe_subscription_id :string
#
# Indexes
#
#  online_service_relation_index         (online_service_id,customer_id,permission_state)
#  online_service_relation_unique_index  (online_service_id,customer_id,current) UNIQUE
#

# payment_state pending, and permission_state active might be purchased from bundler
class OnlineServiceCustomerRelation < ApplicationRecord
  ACTIVE_STATES = %w[pending free paid incomplete partial_paid canceled manual_paid].freeze
  SOLD_STATES = %w[paid partial_paid manual_paid]

  include SayHi
  hi_track_event "online_service_purchased"
  has_paper_trail on: [:update], only: [:payment_state, :permission_state, :product_details, :sale_page_id]

  alias_attribute :watched_episode_ids, :watched_lesson_ids

  has_many :customer_payments, as: :product
  has_one :last_customer_payment, -> { where(state: CustomerPayment::PAYMENT_STATES).order(id: :desc) } , as: :product, class_name: "CustomerPayment"
  belongs_to :online_service
  belongs_to :sale_page, optional: true
  belongs_to :customer
  belongs_to :bundled_service, optional: true

  # Don't add this scope, where("online_services.start_at is NULL or online_services.start_at < :now", now: Time.current)
  # because we need to a scope to filter the relations is legal to send them messages or do something even before service started
  # So this scope couldn't guarantee customer could start to use service since it doesn't check service start time
  scope :available, -> { active.current.unexpired }
  scope :unexpired, -> { where("expire_at is NULL or expire_at >= ?", Time.current) }
  scope :uncanceled, -> { where.not(payment_state: :canceled) }
  scope :current, -> { where(current: true) }
  scope :sold, -> { where(payment_state: SOLD_STATES) }

  enum payment_state: {
    pending: 0,
    free: 1,
    paid: 2,
    failed: 3,
    refunded: 4,
    canceled: 5,
    partial_paid: 6,
    incomplete: 7,
    manual_paid: 8
  }, _suffix: true

  enum permission_state: {
    pending: 0,
    active: 1
  }

  def assignment?
    sale_page.nil?
  end

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
      I18n.l(expire_at, format: :long_date_with_wday)
    elsif canceled_payment_state?
      "#{I18n.l(updated_at, format: :long_date_with_wday)} #{I18n.t("action.stop_usage")}"
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
    state == "inactive"
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

  def upsell_sold?
    if online_service.upsell_sale_page_id && (sale_relation = customer.online_service_customer_relations.where(sale_page_id: online_service.upsell_sale_page_id).current.first)
      sale_relation.purchased?
    else
      false
    end
  end

  def sale_page_service_slug
    if bundler_relation
      bundler_relation.online_service.slug
    else
      online_service.slug
    end
  end

  def hi_message
    "🖥 New online_service purchased, id: #{id}, online_service: #{online_service.slug}, sale_page: #{sale_page&.slug}, customer_id: #{customer_id}, user_id: #{customer.user_id}, payment_state: #{payment_state}, permission_state: #{permission_state}, expire_at: #{expire_at ? I18n.l(expire_at, format: :long_date_with_wday) : ""}"
  end

  def price_details
    product_details["prices"].map do |_attributes|
      if _attributes["bundler_price"]
        bundler_relation.price_details.first
      else
        ::OnlineServiceCustomerPrice.new(_attributes.merge(
          charge_at: _attributes["charge_at"] ? Time.parse(_attributes["charge_at"]) : nil,
          currency: customer.user.currency
        ))
      end
    end
  end

  def user
    @user ||= customer.user
  end

  def bundler_relation
    @bundler_relation ||= sale_page.present? ? OnlineServiceCustomerRelation.where(
      online_service: sale_page.product,
      sale_page: sale_page,
      customer: customer,
    ).where.not(id: id).take : nil
  end

  def bundled_service_relations
    @bundled_service_relations ||= OnlineServiceCustomerRelation.where(
      current: true,
      online_service: sale_page.product.bundled_online_services,
      sale_page: sale_page, # NOTICE: ONLY the one from the same sale page
      customer: customer
    )
  end

  def purchased_from_bundler?
    product_details["prices"].first["bundler_price"]
  end

  def total_completed_payments_amount
    customer_payments.completed.map(&:amount).sum(0)
  end

  def product_amount
    price_details.map { |price| Money.new(price.amount, user.currency) }.sum(0)
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

  def subscription?
    stripe_subscription_id.present? || price_details.first.interval.present? || bundled_service&.subscription
  end

  def forever?
    expire_at.nil? && !subscription?
  end

  def user_currency
    user.currency
  end

  def selling_prices_text
    if purchased_from_bundler?
      bundler_relation.selling_prices_text
    else
      if assignment?
        "N/A"
      elsif free_payment_state?
        I18n.t("common.free_price")
      elsif price_details.first.interval
        if user_currency == "JPY"
          "#{I18n.t("common.#{price_details.first.interval}_pay")} #{price_details.first.amount_with_currency.format(:ja_default_format)}"
        else
          "#{I18n.t("common.#{price_details.first.interval}_pay")} #{price_details.first.amount_with_currency.format}"
        end
      elsif online_service.external?
        I18n.t("common.contact_owner_directly")
      elsif price_details.size == 1
        if user_currency == "JPY"
          "#{I18n.t("common.one_time_pay")} #{price_details.first.amount_with_currency.format(:ja_default_format)}"
        else
          "#{I18n.t("common.one_time_pay")} #{price_details.first.amount_with_currency.format}"
        end
      else
        times = price_details.size
        amount_with_currency = price_details.first.amount_with_currency

        if user_currency == "JPY"
          "#{I18n.t("common.multiple_times_pay")} #{amount_with_currency.format(:ja_default_format)} X #{times} #{I18n.t("common.times")}"
        else
          "#{I18n.t("common.multiple_times_pay")} #{amount_with_currency.format} X #{times} #{I18n.t("common.times")}"
        end
      end
    end
  end
end
