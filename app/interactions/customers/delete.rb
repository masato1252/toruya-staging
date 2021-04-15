# frozen_string_literal: true

class Customers::Delete < ActiveInteraction::Base
  object :customer
  boolean :soft_delete, default: true

  def execute
    if soft_delete
      customer.update_columns(deleted_at: Time.current)
      User.reset_counters(customer.user_id, :customers)
    else
      customer.destroy
    end
  end
end
