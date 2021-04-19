# == Schema Information
#
# Table name: customer_payments
#
#  id                    :bigint(8)        not null, primary key
#  customer_id           :bigint(8)
#  amount_cents          :decimal(, )
#  amount_currency       :string
#  product_id            :integer
#  product_type          :string
#  state                 :integer          default(0), not null
#  charge_at             :datetime
#  expired_at            :datetime
#  manual                :boolean          default(FALSE), not null
#  stripe_charge_details :jsonb
#  order_id              :string
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
# Indexes
#
#  index_customer_payments_on_customer_id                  (customer_id)
#  index_customer_payments_on_product_id_and_product_type  (product_id,product_type)
#

class CustomerPayment < ApplicationRecord
  belongs_to :product, polymorphic: true
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
end
