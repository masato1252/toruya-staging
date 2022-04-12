# frozen_string_literal: true

class RecurringPrice
  include ActiveAttr::Model

  attribute :interval, type: String
  attribute :amount, type: Integer
  attribute :stripe_price_id, type: String
  attribute :active, default: false

  validates :interval, inclusion: { in: %w[month year] }
  validates :active, inclusion: { in: [true, false] }
  validates :amount, numericality: { greater_than: 0 }
  validates_presence_of :interval, :amount, :active, :stripe_price_id
end

