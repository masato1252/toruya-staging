class Customers::Filter < ActiveInteraction::Base
  object :super_user, class: User
  array :group_ids, default: nil
  string :region, default: nil
  array :cities, default: nil
  boolean :has_email, default: nil
  array :email_types, default: nil
  object :dob_range, default: nil, class: Range
  array :custom_ids, default: nil
  hash :reservation, default: nil do
    boolean :has_reservation, default: nil
    object :date_range, default: nil, class: Range
    array :menu_ids, default: nil
    array :staff_ids, default: nil
    boolean :with_warnings, default: nil
    array :states, default: nil
  end

  def execute
    scoped = super_user.customers.includes(:rank, :contact_group, :updated_by_user)

    scoped = scoped.where(contact_group_id: group_ids) if group_ids.present?

    if region.present?
      if cities.present?
        cities_sql = cities.map {|city| "address = '#{region} #{city}'"}.join(" OR ")
        scoped = scoped.where(cities_sql)
      else
        scoped = scoped.where("address ilike ?", "#{region}%")
      end
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

    scoped = scoped.where(birthday: dob_range) if dob_range.present?

    if custom_ids.present?
      custom_ids_sql = custom_ids.map {|custom_id| "custom_id ilike '%#{custom_id}%'"}.join(" OR ")
      scoped = scoped.where(custom_ids_sql)
    end

    if reservation && !reservation[:has_reservation].nil?
      if reservation[:has_reservation]
        if reservation[:date_range].present?
          scoped = scoped.left_outer_joins(:reservations).where("reservations.start_time": reservation[:date_range])
        else
          scoped = scoped.left_outer_joins(:reservations).where("reservations.id is not NULL")
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
      end
    end

    scoped
  end
end
