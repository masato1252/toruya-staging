# == Schema Information
#
# Table name: online_service_customer_relations
#
#  id                :bigint           not null, primary key
#  expire_at         :datetime
#  paid_at           :datetime
#  payment_state     :integer          default("pending"), not null
#  permission_state  :integer          default("pending"), not null
#  product_details   :json
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  customer_id       :integer          not null
#  online_service_id :integer          not null
#  sale_page_id      :integer          not null
#
# Indexes
#
#  online_service_relation_index         (online_service_id,customer_id,permission_state)
#  online_service_relation_unique_index  (online_service_id,customer_id) UNIQUE
#

class OnlineServiceCustomerRelation < ApplicationRecord
  include SayHi

  belongs_to :online_service
  belongs_to :sale_page
  belongs_to :customer

  scope :available, -> { active.where("expire_at is NULL or expire_at >= ?", Time.current) }

  enum payment_state: {
    pending: 0,
    free: 1,
    paid: 2,
    failed: 3,
    refunded: 4
  }, _suffix: true

  enum permission_state: {
    pending: 0,
    active: 1
  }

  def approved_at
    paid_at || created_at if active?
  end

  def state
    if pending?
      "pending"
    elsif active? && expire_at && expire_at < Time.current
      "inactive"
    else
      "available"
    end
  end

  def purchased?
    free_payment_state? || paid_payment_state?
  end

  def hi_message
    "🖥 New online_service purchased, online_service: #{online_service.slug}, sale_page: #{sale_page.slug}, customer_id: #{customer_id}, user_id: #{customer.user_id}, payment_state: #{payment_state}, permission_state: #{permission_state}, expire_at: #{expire_at ? I18n.l(expire_at, format: :long_date_with_wday) : ""}"
  end
end
