class Customers::Filter < ActiveInteraction::Base
  object :super_user, class: User
  array :group_ids, default: nil
  hash :living_place, default: nil do
    boolean :inside, default: true
    array :states, default: nil
  end
  boolean :has_email, default: nil
  array :email_types, default: nil
  hash :birthday, default: nil do
    string :query_type, default: "on"
    date :start_date, default: nil
    date :end_date, default: nil
  end

  object :dob_range, default: nil, class: Range
  array :custom_ids, default: nil
  hash :reservation, default: nil do
    boolean :has_reservation, default: nil
    string :query_type, default: "on"
    time :start_date, default: nil
    time :end_date, default: nil
    array :menu_ids, default: nil
    array :staff_ids, default: nil
    boolean :with_warnings, default: nil
    array :states, default: nil
  end

  def execute
    scoped = super_user.customers.includes(:rank, :contact_group, :updated_by_user)

    scoped = scoped.where(contact_group_id: group_ids) if group_ids.present?

    if living_place && living_place[:states].present?
      if living_place[:inside]
        states_sql = living_place[:states].map { |state| "address like '#{state}%'"}.join(" OR ")
      else
        states_sql = living_place[:states].map { |state| "address NOT like '#{state}%'"}.join(" AND ")
      end

      scoped = scoped.where(states_sql)
    end

    if !has_email.nil?
      if has_email
        if email_types.present?
          email_type_sql = email_types.map {|type| "email_types like '%#{type}%'"}.join(" OR ")
          scoped = scoped.where(email_type_sql)
        else
          scoped = scoped.where("email_types is not NULL")
        end
      else
        scoped = scoped.where("email_types is NULL")
      end
    end

    if birthday && birthday[:start_date]
      scoped = case birthday[:query_type]
               when "on"
                 scoped.where(birthday: birthday[:start_date])
               when "before"
                 scoped.where("birthday < ?", birthday[:start_date])
               when "after"
                 scoped.where("birthday > ?", birthday[:start_date])
               when "between"
                 scoped.where(birthday: birthday[:start_date]..birthday[:end_date])
               end
    end

    if custom_ids.present?
      custom_ids_sql = custom_ids.map {|custom_id| "custom_id ilike '%#{custom_id}%'"}.join(" OR ")
      scoped = scoped.where(custom_ids_sql)
    end

    if reservation && !reservation[:has_reservation].nil?
      if reservation[:has_reservation]
        scoped = scoped.includes(:reservations).references(:reservations)

        if reservation[:start_date].present?
          scoped = case reservation[:query_type]
                   when "on"
                     scoped.where("reservations.start_time": reservation[:start_date]..reservation[:start_date].end_of_day)
                   when "before"
                     scoped.where("reservations.start_time < ?", reservation[:start_date])
                   when "after"
                     scoped.where("reservations.start_time > ?", reservation[:start_date].end_of_day)
                   when "between"
                     scoped.where("reservations.start_time": reservation[:start_date]..reservation[:end_date])
                   end
        else
          scoped = scoped.where("reservations.id is not NULL")
        end

        if reservation[:menu_ids].present?
          scoped = scoped.where("reservations.menu_id": reservation[:menu_ids])
        end

        if reservation[:staff_ids].present?
          scoped = scoped.left_outer_joins(:reservations => :reservation_staffs).
            where("reservation_staffs.staff_id": reservation[:staff_ids])
        end

        if !reservation[:with_warnings].nil?
          scoped = scoped.where("reservations.with_warnings": reservation[:with_warnings])
        end

        if reservation[:states].present?
          scoped = scoped.where("reservations.aasm_state": reservation[:states])
        end
      else
        # No reservation case
        scoped = scoped.left_outer_joins(:reservations)

        if reservation[:start_date].present?
          scoped = case reservation[:query_type]
                   when "on"
                     scoped.where.not("reservations.start_time": reservation[:start_date]..reservation[:start_date].end_of_day)
                   when "before"
                     scoped.where.not("reservations.start_time < ?", reservation[:start_date])
                   when "after"
                     scoped.where.not("reservations.start_time > ?", reservation[:start_date].end_of_day)
                   when "between"
                     scoped.where.not("reservations.start_time": reservation[:start_date]..reservation[:end_date])
                   end
        else
          scoped = scoped.where("reservations.id is NULL")
        end
      end
    end

    scoped.distinct
  end
end
