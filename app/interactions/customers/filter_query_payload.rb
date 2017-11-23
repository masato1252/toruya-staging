class Customers::FilterQueryPayload < ActiveInteraction::Base
  hash :param, strip: false

  def execute
    query = {}

    if param[:group_ids].present?
      query[:group_ids] = param[:group_ids].split(",")
    end

    if param[:rank_ids].present?
      query[:rank_ids] = param[:rank_ids].split(",")
    end

    if param[:living_place].present? &&  param[:living_place][:states].present?
      query[:living_place] = param[:living_place].merge(states: param[:living_place][:states].split(","))
    end

    if param[:has_email].present?
      query[:has_email] = param[:has_email]
    end

    if param[:email_types].present?
      query[:email_types] = param[:email_types].split(",")
    end

    if param[:birthday].present?
      if param[:birthday][:start_date].present? || param[:birthday][:month].present?
        if param[:birthday][:start_date].present?
          query[:birthday] = param[:birthday].merge(
            start_date: Date.parse(param[:birthday][:start_date])
          )
        end

        if param[:birthday][:month].present?
          query[:birthday] = param[:birthday]
        end

        if param[:birthday][:end_date].present?
          query[:birthday][:end_date] = Date.parse(param[:birthday][:end_date])
        end
      end
    end

    if param[:custom_ids].present?
      query[:custom_ids] = param[:custom_ids].split(",")
    end

    if param[:reservation].present? && param[:reservation][:start_date].present?
      query[:reservation] = param[:reservation].merge(
        start_date: Date.parse(param[:reservation][:start_date]).beginning_of_day
      )

      if param[:reservation][:end_date]
        query[:reservation][:end_date] = Date.parse(param[:reservation][:end_date]).end_of_day
      end

      if param[:reservation][:menu_ids].present?
        query[:reservation][:menu_ids] = param[:reservation][:menu_ids].split(",")
      end

      if param[:reservation][:staff_ids].present?
        query[:reservation][:staff_ids] = param[:reservation][:staff_ids].split(",")
      end

      if param[:reservation][:states].present?
        query[:reservation][:states] = param[:reservation][:states].split(",")
      end
    end

    query
  end
end
