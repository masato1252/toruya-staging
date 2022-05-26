# frozen_string_literal: true

require "line_client"

class Lines::Actions::ActiveOnlineServices < ActiveInteraction::Base
  object :social_customer
  integer :last_relation_id, default: nil

  def execute
    unless customer
      compose(Lines::Menus::Guest, social_customer: social_customer)

      return
    end

    compose(Notifiers::Customers::OnlineServices::ActiveRelations, receiver: customer, last_relation_id: last_relation_id)
  end

  private

  def customer
    @customer ||= social_customer.customer
  end
end
