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
        when "age_range"
          age_range_scoped(filter)
        when "date_month_eq"
          date_month_eq_scoped(filter)
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
          when "age_range"
            age_range_scoped(filter)
          when "date_month_eq"
            date_month_eq_scoped(filter)
          end

        if query["operator"] == "or"
          scoped = scoped.or(new_scoped)
        elsif query["operator"] == "and"
          scoped = scoped.merge(new_scoped)
        end
      end

      scoped#.active_in(1.year.ago)
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

    # {
    #   "filters" => [
    #     {
    #       "field" => "birthday",
    #       "value" => [18, 25],
    #       "condition" => "age_range"
    #     },
    #     {
    #       "field" => "birthday",
    #       "value" => 3,
    #       "condition" => "date_month_eq"
    #     }
    #   ],
    #   "operator" => "and"
    # }
    def age_range_scoped(filter)
      year_end = Time.zone.now.year - filter["value"][0].to_i
      year_start = Time.zone.now.year - filter["value"][1].to_i

      user.customers.where("EXTRACT(YEAR FROM #{filter["field"]}) >= ?", year_start).where("EXTRACT(YEAR FROM #{filter["field"]}) <= ?", year_end)
    end

    def date_month_eq_scoped(filter)
      user.customers.where("EXTRACT(MONTH FROM #{filter["field"]}) = ?", filter["value"].to_i)
    end
  end
end
