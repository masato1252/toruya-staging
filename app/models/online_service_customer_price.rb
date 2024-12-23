# frozen_string_literal: true

class OnlineServiceCustomerPrice
  include ActiveAttr::Model

  attribute :interval, type: String
  attribute :amount, type: Integer
  attribute :currency, type: String
  attribute :stripe_price_id, type: String
  attribute :charge_at, type: DateTime
  attribute :order_id, type: String
  attribute :bundler_price, type: Boolean

  validates_presence_of :amount, allow_nil: true # bundler price is nil
  validates :interval, inclusion: { in: %w[month year] }, allow_nil: true

  validate :validate_price

  def amount_with_currency
    Money.new(amount, currency) if amount
  end

  def price_type
    if recurring_price_required_conditions
      # recurring price: monthly, yearly pay
      return "recurring_price"
    end

    if free_price_required_conditions
      # free
      return "free"
    end

    if bundler_price_required_conditions
      # one time or multiple time
      return "bundler_price"
    end

    if non_recurring_price_required_conditions
      # one time or multiple time
      return "non_recurring_price"
    end
  end

  private

  def validate_price
    if interval.present?
      # recurring price: monthly, yearly pay
      unless recurring_price_required_conditions
        errors.add(:base, :invalid_recurring_price)
      end
    elsif amount.zero?
      # free
      unless free_price_required_conditions
        errors.add(:base, :invalid_free_price)
      end
    elsif amount.nil?
      unless bundler_price_required_conditions
        errors.add(:base, :invalid_bundler_price)
      end
    else
      # one time or multiple time
      unless non_recurring_price_required_conditions
        errors.add(:base, :invalid_price)
      end
    end
  end

  def recurring_price_required_conditions
    interval.present? && amount.positive? && stripe_price_id.present? && charge_at.blank? && order_id.blank?
  end

  def free_price_required_conditions
    interval.blank? && amount.zero? && stripe_price_id.blank? && charge_at.present? && order_id.blank?
  end

  def non_recurring_price_required_conditions
    interval.blank? && amount.positive? && stripe_price_id.blank? && charge_at.present? && order_id.present?
  end

  def bundler_price_required_conditions
    interval.blank? && amount.nil? && stripe_price_id.blank? && charge_at.present? && order_id.blank?
  end
end

