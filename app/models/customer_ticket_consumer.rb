# == Schema Information
#
# Table name: customer_ticket_consumers
#
#  id                    :bigint           not null, primary key
#  consumer_type         :string           not null
#  ticket_quota_consumed :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  consumer_id           :bigint           not null
#  customer_ticket_id    :bigint           not null
#
# Indexes
#
#  consumer_ticket_index                                  (consumer_id,consumer_type) UNIQUE
#  index_customer_ticket_consumers_on_consumer            (consumer_type,consumer_id)
#  index_customer_ticket_consumers_on_customer_ticket_id  (customer_ticket_id)
#
class CustomerTicketConsumer < ApplicationRecord
  belongs_to :consumer, polymorphic: true # ReservationCustomer
  belongs_to :customer_ticket
end
