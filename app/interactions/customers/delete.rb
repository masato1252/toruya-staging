# frozen_string_literal: true

class Customers::Delete < ActiveInteraction::Base
  object :customer
  boolean :soft_delete, default: true

  def execute
    Customer.transaction do
      if soft_delete
        customer.update_columns(deleted_at: Time.current)
        customer.user.update_columns(customers_count: customer.user.customers.count)
      else
        customer.destroy
      end
    end
  end
end
