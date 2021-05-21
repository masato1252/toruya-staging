module Broadcasts
  class FilterCustomers < ActiveInteraction::Base
    object :broadcast

    def execute
      compose(Broadcasts::QueryCustomers, user: broadcast.user, query: broadcast.query)
    end
  end
end
