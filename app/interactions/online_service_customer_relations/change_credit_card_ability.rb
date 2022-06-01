# frozen_string_literal: true

class OnlineServiceCustomerRelations::ChangeCreditCardAbility < ActiveInteraction::Base
  object :relation, class: OnlineServiceCustomerRelation

  def execute
    return false if online_service.external?
    return relation.legal_to_access? if online_service.recurring_charge_required?

    # no fail order and not paid completed
    relation.order_completed.values.all?(true) && !relation.paid_completed?
  end

  private

  def online_service
    @online_service ||= relation.online_service
  end
end
