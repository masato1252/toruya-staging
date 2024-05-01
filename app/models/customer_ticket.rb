# == Schema Information
#
# Table name: customer_tickets
#
#  id             :bigint           not null, primary key
#  code           :string           not null
#  consumed_quota :integer          default(0), not null
#  expire_at      :datetime
#  state          :string           not null
#  total_quota    :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :bigint           not null
#  ticket_id      :bigint           not null
#
# Indexes
#
#  index_customer_tickets_on_code         (code)
#  index_customer_tickets_on_customer_id  (customer_id)
#  index_customer_tickets_on_ticket_id    (ticket_id)
#
class CustomerTicket < ApplicationRecord
  has_many :customer_ticket_consumers
  belongs_to :ticket
  scope :unexpired, -> { where("expire_at > ?", Time.current) }
  scope :expired, -> { where("expire_at <= ?", Time.current) }

  enum state: {
    active: 'active',
    completed: 'completed'
  }
end
