class Reservations::Filter < ActiveInteraction::Base
  object :super_user, class: User
  hash :reservation, default: nil do
    array :shop_ids
    time :start_date
    string :query_type, default: "on"
    time :end_date, default: nil
    array :menu_ids, default: nil
    array :staff_ids, default: nil
    boolean :with_warnings, default: nil
    array :states, default: nil
  end

  def execute
    scoped = Reservation.where(shop_id: reservation[:shop_ids]).includes(:shop, :menu, :customers, :staffs)

    scoped = case reservation[:query_type]
             when "on"
               scoped.where("start_time": reservation[:start_date]..reservation[:start_date].end_of_day)
             when "before"
               scoped.where("start_time < ?", reservation[:start_date])
             when "after"
               scoped.where("start_time > ?", reservation[:start_date].end_of_day)
             when "between"
               scoped.where("start_time": reservation[:start_date]..reservation[:end_date])
             end

    if reservation[:menu_ids].present?
      scoped = scoped.where("menu_id": reservation[:menu_ids])
    end

    if reservation[:staff_ids].present?
      scoped = scoped.left_outer_joins(:reservation_staffs).
        where("reservation_staffs.staff_id": reservation[:staff_ids])
    end

    if !reservation[:with_warnings].nil?
      scoped = scoped.where("with_warnings": reservation[:with_warnings])
    end

    if reservation[:states].present?
      scoped = scoped.where("aasm_state": reservation[:states])
    end

    scoped.order("start_time DESC").distinct
  end
end
