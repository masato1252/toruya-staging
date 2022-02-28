# frozen_string_literal: true

class OnlineServiceCustomerPrice
  include ActiveAttr::Model

  attribute :interval, type: String
  attribute :amount, type: Integer
  attribute :stripe_price_id, type: String
  attribute :charge_at, type: DateTime
  attribute :order_id, type: String

  validates_presence_of :amount
  validates :interval, inclusion: { in: %w[month year] }, allow_nil: true

  validate :validate_price

  def validate_price
    if interval.present?
      # recurring price: monthly, yearly pay
      unless recurring_price_required_conditons
        errors.add(:base, :invalid_recurring_price)
      end
    elsif amount.zero?
      # free
      unless free_price_required_conditons
        errors.add(:base, :invalid_free_price)
      end
    else
      # one time or multiple time
      unless non_recurring_price_required_conditons
        errors.add(:base, :invalid_price)
      end
    end
  end

  def price_type
    if recurring_price_required_conditons
      # recurring price: monthly, yearly pay
      return "recurring_price"
    end

    if free_price_required_conditons
      # free
      return "free"
    end

    if non_recurring_price_required_conditons
      # one time or multiple time
      return "non_recurring_price"
    end
  end

  private

  def recurring_price_required_conditons
    interval.present? && amount.positive? && stripe_price_id.present? && charge_at.blank? && order_id.blank?
  end

  def free_price_required_conditons
    interval.blank? && amount.zero? && stripe_price_id.blank? && charge_at.present? && order_id.blank?
  end

  def non_recurring_price_required_conditons
    interval.blank? && amount.positive? && stripe_price_id.blank? && charge_at.present? && order_id.present?
  end
end

