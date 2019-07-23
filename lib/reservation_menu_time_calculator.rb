module ReservationMenuTimeCalculator
  def self.calculate(reservation, reservation_menus, position)
    is_first_menu = position == 0
    is_last_menu = position + 1 == reservation_menus.count

    work_start_at = reservation.start_time.advance(minutes: reservation_menus.slice(0, position).sum(&:required_time))
    work_end_at = work_start_at.advance(minutes: reservation_menus[position].required_time)

    {
      prepare_time: is_first_menu ? reservation.prepare_time : work_start_at || reservation.prepare_time,
      work_start_at: work_start_at,
      work_end_at: work_end_at,
      ready_time: is_last_menu ? reservation.ready_time : work_end_at || reservation.ready_time
    }
  end
end
