# frozen_string_literal: true

class OnlineServiceCustomerRelations::ReconnectBestContract < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation

  def execute
    new_best_available_contract_relation =
      OnlineServiceCustomerRelation.
      where(online_service_id: relation.online_service_id, customer_id: relation.customer_id, current: nil).
      where.not(id: relation.id).
      where("expire_at is NULL or expire_at > ?", Time.current).
      order("expire_at DESC NULLS FIRST").
      first

    if new_best_available_contract_relation
      new_best_available_contract_relation.with_lock do
        relation.current = nil
        relation.pending!

        new_best_available_contract_relation.current = true
        new_best_available_contract_relation.active!

        new_best_available_contract_relation
      end
    else
      if relation.bundler_relation&.expire_at?
        relation.expire_at = relation.bundler_relation.expire_at
        relation.save!
      else
        relation.pending!
      end

      relation
    end
  end
end
