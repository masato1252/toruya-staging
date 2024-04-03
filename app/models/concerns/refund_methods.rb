# frozen_string_literal: true

module RefundMethods
  extend ActiveSupport::Concern

  private

  def refund_payment(payment_refund_response = nil)
    ApplicationRecord.transaction do
      payment = customer.customer_payments.create!(
        product: product,
        amount: -amount,
        manual: true
      )

      payment.charge_details = payment_refund_response
      payment.refunded!
      product_refund

      if product.is_a?(OnlineServiceCustomerRelation)
        # Only bundler had bundled_service_relations
        product.bundled_service_relations.each do |bundled_service_relation|
          OnlineServiceCustomerRelations::ReconnectBestContract.run(relation: bundled_service_relation)
        end
      end
    end
  end

  def customer
    @customer ||= customer_payment.customer
  end

  def product
    customer_payment.product
  end

  def owner
    @owner ||= customer.user
  end

  def product_refund
    product.is_a?(ReservationCustomer) ? product.payment_refunded! : product.refunded_payment_state!
  end

  def payment_refunded
    product.is_a?(ReservationCustomer) ? product.payment_refunded? : product.refunded_payment_state?
  end

  def validate_refundable
    errors.add(:customer_payment, :charge_already_refunded) if payment_refunded
  end

  def validate_amount
    if amount > customer_payment.amount
      errors.add(:customer_payment, :else)
    end

    unless amount.positive?
      errors.add(:customer_payment, :else)
    end
  end
end
