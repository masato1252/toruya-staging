# == Schema Information
#
# Table name: online_service_customer_relations
#
#  id                :bigint(8)        not null, primary key
#  online_service_id :integer          not null
#  sale_page_id      :integer          not null
#  customer_id       :integer          not null
#  payment_state     :integer          default("pending"), not null
#  permission_state  :integer          default("pending"), not null
#  paid_at           :datetime
#  expire_at         :datetime
#  product_details   :json
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  online_service_relation_index         (online_service_id,customer_id,permission_state)
#  online_service_relation_unique_index  (online_service_id,customer_id) UNIQUE
#

class OnlineServiceCustomerRelation < ApplicationRecord
  belongs_to :online_service
  belongs_to :sale_page
  belongs_to :customer

  enum payment_state: {
    pending: 0,
    free: 1,
    paid: 2,
    auth_failed: 3,
    processor_failed: 4,
  }, _suffix: true

  enum permission_state: {
    pending: 0,
    active: 1,
  }

  def purchased?
    free_payment_state? || paid_payment_state?
  end
end
