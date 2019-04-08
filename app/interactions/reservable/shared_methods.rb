module Reservable
  module SharedMethods
    def reserved_staff_ids(menu=nil)
      # reservation_id.presence: sql don't support reservation_id pass empty string
      # start_time/ready_time checking is >, < not, >=, <= that means we accept reservation is overlap 1 minute
      return @reserved_staff_ids if defined?(@reserved_staff_ids)

      scoped = ReservationStaff.joins(reservation: :menu).
        where.not(reservation_id: reservation_id.presence).
        where("reservation_staffs.staff_id": shop.staff_ids).
        where("reservations.deleted_at": nil).
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
      pluck(Arel.sql("DISTINCT staff_id"))
    end

    def closed_custom_schedules
      CustomSchedule.
        closed.
        where("custom_schedules.start_time < ? and custom_schedules.end_time > ?", end_time, start_time).includes(:staff)
    end

    # TODO: [Personal schedule legacy] Remove staff custom off schedule query when it indeed doesn't be used
    def closed_custom_schedules_staff_ids
      @closed_custom_schedules_staff_ids ||= closed_custom_schedules.
        where(staff_id: shop.staff_ids).
        pluck(Arel.sql("DISTINCT custom_schedules.staff_id")) +
      closed_personal_custom_schedules_staff_ids
    end

    def closed_personal_custom_schedules_staff_ids
      active_staff_accounts = shop.user.owner_staff_accounts.active.to_a

      closed_schedule_user_ids = closed_custom_schedules.
        where(user_id: active_staff_accounts.map(&:user_id)).
        pluck(Arel.sql("DISTINCT custom_schedules.user_id"))

      active_staff_accounts.find_all {|staff_account| closed_schedule_user_ids.include?(staff_account.user_id) }.map(&:staff_id)
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
