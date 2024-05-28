# == Schema Information
#
# Table name: tickets
#
#  id          :bigint           not null, primary key
#  ticket_type :string           default("single")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint
#
# Indexes
#
#  index_tickets_on_user_id  (user_id)
#
class Ticket < ApplicationRecord
  belongs_to :user
  has_many :ticket_products # what product could use this ticket
  has_many :customer_tickets

  enum ticket_type: {
    single: 'single'
  }
end
