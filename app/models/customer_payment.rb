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
#  product_type          :string
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
  belongs_to :product, polymorphic: true
  belongs_to :customer
  monetize :amount_cents

  enum state: {
    active: 0,
    completed: 1,
    refunded: 2,
    auth_failed: 3,
    processor_failed: 4,
    refund_failed: 5,
    bonus: 6
  }

  def failed?
    auth_failed? || processor_failed?
  end

  def bonus_text
    bonus_info_json = JSON.parse(order_id)
    payment_bonus = CustomerPaymentBonus.new(bonus_info_json)
    sale_page = SalePage.find_by(id: payment_bonus.sale_page_id)

    I18n.t("user_bot.dashboards.settings.service_customer_relation.free_bonus", service_name: sale_page.product_name, free_bonus_month: payment_bonus.bonus_month)
  rescue JSON::ParserError
    nil
  end
end
