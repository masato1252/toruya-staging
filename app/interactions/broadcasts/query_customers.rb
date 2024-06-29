module Broadcasts
  class QueryCustomers < ActiveInteraction::Base
    object :user
    hash :query, strip: false, default: nil
    # {
    #   "filters" => [
    #     {
    #       "field" => "online_service_ids",
    #       "value" => 189,
    #       "condition" => "contains"
    #     }
    #   ],
    #   "operator" => "or"
    # }

    def execute
      scoped = user.customers
      return scoped if query.blank?
      return scoped if query["filters"].blank?

      filter = query["filters"][0]

      scoped =
        case filter["condition"]
        when "contains"
          contains_scoped(filter)
        when "not_contains"
          not_contains_scoped(filter)
        when "eq"
          eq_scoped(filter)
        end

      query["filters"][1..-1].each do |filter|
        new_scoped =
          case filter["condition"]
          when "contains"
            contains_scoped(filter)
          when "not_contains"
            not_contains_scoped(filter)
          when "eq"
            eq_scoped(filter)
          end

        if query["operator"] == "or"
          scoped = scoped.or(new_scoped)
        elsif query["operator"] == "and"
          scoped = scoped.merge(new_scoped)
        end
      end

      scoped.active_in(1.year.ago)
    end

    private

    def not_contains_scoped(filter)
      user.customers.where.not("#{filter["field"]} && ?", "{#{filter["value"]}}")
    end

    def contains_scoped(filter)
      user.customers.where("#{filter["field"]} && ?", "{#{filter["value"]}}")
    end

    def eq_scoped(filter)
      user.customers.joins(:rank).where("#{filter["field"]} = ?", filter["value"])
    end
  end
end
