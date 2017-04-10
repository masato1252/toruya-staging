module Reservable
  module SharedMethods
    def reserved_staff_ids(menu=nil)
      # reservation_id.presence: sql don't support reservation_id pass empty string
      # start_time/ready_time checking is >, < not, >=, <= that means we accept reservation is overlap 1 minute
      return @reserved_staff_ids if defined?(@reserved_staff_ids)

      scoped = ReservationStaff.joins(reservation: :menu).
        where.not(reservation_id: reservation_id.presence).
        where("reservation_staffs.staff_id": shop.staff_ids).
        where.not("menus.min_staffs_number" => 0)

      overlap_scoped = if menu
                scoped.where("(reservations.start_time < ? and reservations.ready_time > ?)", end_time + menu.interval.minutes, start_time)
              else
                scoped.where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)", end_time, start_time)
              end

      @reserved_staff_ids =
        overlap_scoped.
        or(
          scoped.where("reservations.shop_id != ?", shop.id).where("reservations.start_time > ? and reservations.end_time <= ?", beginning_of_day, end_of_day)
      ).
        pluck("DISTINCT staff_id")
    end

    def closed_custom_schedules_staff_ids
      CustomSchedule.
        where(staff_id: shop.staff_ids).
        closed.
        where("custom_schedules.start_time < ? and custom_schedules.end_time > ?", end_time, start_time).
        pluck("DISTINCT staff_id")
    end

    def overlap_reservations(menu_id=nil)
      # XXX: TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)
      # a range time is available or not, it is depend on what menu it used,
      # so we use the above query to find all the available menus when using our query time range.
      scoped = shop.reservations.left_outer_joins(:menu, :reservation_customers, :staffs => :staff_menus).
        where.not(id: reservation_id.presence).
        where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)", end_time, start_time)

      scoped = scoped.where("menus.id = ?", menu_id) if menu_id
      scoped.select("reservations.*").group("reservations.id")
    end

    def today
      @today ||= ::Time.zone.now.to_s(:date)
    end

    def start_time
      @start_time ||= business_time_range.first
    end

    def end_time
      @end_time ||= business_time_range.last
    end

    def beginning_of_day
      @beginning_of_day ||= start_time.beginning_of_day
    end

    def end_of_day
      @end_of_day ||= start_time.end_of_day
    end
  end
end
