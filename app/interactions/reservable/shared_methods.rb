module Reservable
  module SharedMethods
    def reserved_staff_ids
      # reservation_id.presence: sql don't support reservation_id pass empty string
      # start_time/ready_time checking is >, < not, >=, <= that means we accept reservation is overlap 1 minute
      return @reserved_staff_ids if defined?(@reserved_staff_ids)

      beginning_of_day = start_time.beginning_of_day
      end_of_day = start_time.end_of_day

      scoped = ReservationStaff.joins(reservation: :menu).
        where.not(reservation_id: reservation_id.presence).
        where("reservation_staffs.staff_id": shop.staff_ids).
        where.not("menus.min_staffs_number" => 0)

      @reserved_staff_ids =
        scoped.where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)", end_time, start_time).
        or(
          scoped.where("reservations.shop_id != ?", shop.id).where("reservations.start_time > ? and reservations.end_time <= ?", beginning_of_day, end_of_day)
      ).
        pluck("DISTINCT staff_id")
    end

    def custom_schedules_staff_ids
      CustomSchedule.
        where(staff_id: shop.staff_ids).
        where("custom_schedules.start_time < ? and custom_schedules.end_time > ?", end_time, start_time).
        pluck("DISTINCT staff_id")
    end

    def overlap_reservations(menu_id=nil)
      scoped = shop.reservations.left_outer_joins(:menu, :reservation_customers, :staffs => :staff_menus).
        where.not(id: reservation_id.presence).
        where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)", end_time, start_time)

      scoped = scoped.where("menus.id = ?", menu_id) if menu_id
      scoped.select("reservations.*").group("reservations.id")
    end

    def start_time
      @start_time ||= business_time_range.first
    end

    def end_time
      @end_time ||= business_time_range.last
    end
  end
end
