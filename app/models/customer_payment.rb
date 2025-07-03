# == Schema Information
#
# Table name: customer_payments
#
#  id                    :bigint           not null, primary key
#  amount_cents          :decimal(, )
#  amount_currency       :string
#  charge_at             :datetime
#  expired_at            :datetime
#  manual                :boolean          default(FALSE), not null
#  memo                  :string
#  product_type          :string
#  provider              :string           default("stripe_connect")
#  state                 :integer          default("active"), not null
#  stripe_charge_details :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  customer_id           :bigint
#  order_id              :string
#  product_id            :integer
#
# Indexes
#
#  index_customer_payments_on_customer_id                  (customer_id)
#  index_customer_payments_on_product_id_and_product_type  (product_id,product_type)
#

class CustomerPayment < ApplicationRecord
  NON_PAYMENT_STATES = %i(change_expire_at)
  PAYMENT_STATES = %i(active completed refunded auth_failed processor_failed refund_failed bonus)

  # order_id need to be unique, under the same product_type and product_id and customer_id
  validates :order_id, uniqueness: { scope: [:product_type, :product_id, :customer_id] }
  belongs_to :product, polymorphic: true
  belongs_to :customer
  monetize :amount_cents

  scope :payment_type, -> { where(state: PAYMENT_STATES) }
  alias_attribute :charge_details, :stripe_charge_details

  enum state: {
    active: 0,
    completed: 1,
    refunded: 2,
    auth_failed: 3,
    processor_failed: 4,
    refund_failed: 5,
    bonus: 6,
    change_expire_at: 7,
    canceled: 8,
    manually_approved: 9
  }

  enum provider: {
    stripe_connect: "stripe_connect",
    square: "square"
  }

  def failed?
    auth_failed? || processor_failed?
  end

  def bonus_text
    return if order_id.blank?

    bonus_info_json = JSON.parse(order_id)
    payment_bonus = CustomerPaymentBonus.new(bonus_info_json)
    sale_page = SalePage.find_by(id: payment_bonus.sale_page_id)

    I18n.t("user_bot.dashboards.settings.service_customer_relation.free_bonus", service_name: sale_page.product_name, free_bonus_month: payment_bonus.bonus_month)
  rescue JSON::ParserError, ActionView::Template::Error
    nil
  end

  def invoice_id
    if stripe_connect? && stripe_charge_details.present?
      "Stripe Invoice ID: #{stripe_charge_details.dig("data", "object", "number")}"
    end
  rescue => e
    nil
  end
end
