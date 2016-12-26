# == Schema Information
#
# Table name: shops
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  name            :string           not null
#  short_name      :string           not null
#  zip_code        :string           not null
#  phone_number    :string           not null
#  email           :string           not null
#  address         :string           not null
#  website         :string
#  holiday_working :boolean
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Shop < ApplicationRecord
  include ReservationChecking

  validates :name, presence: true, uniqueness: { scope: :user_id }, format: { without: /\// }
  validates :short_name, presence: true, uniqueness: { scope: :user_id }
  validates :zip_code, presence: true
  validates :phone_number, presence: true
  validates :email, presence: true
  validates :address, presence: true

  has_many :shop_staffs, dependent: :destroy
  has_many :staffs, through: :shop_staffs
  has_many :shop_menus, dependent: :destroy
  has_many :menus, through: :shop_menus
  has_many :business_schedules
  has_many :custom_schedules
  has_many :customers
  has_many :reservations
  belongs_to :user

  def to_param
    if name.parameterize.present?
      "#{id}-#{name.parameterize}"
    else
      "#{id}-#{name.tr(" ", "")}"
    end
  end

  def available_time(date)
    # Custom -> Holiday -> Business

    # Custom
    if custom_close_schedule = custom_schedules.where(start_time: date.beginning_of_day..date.end_of_day).order("end_time").last
      schedule = business_schedule(date)

      if schedule
        return custom_close_schedule.end_time..schedule.end_time
      else
        return
      end
    end

    # Holiday
    if date.holiday?(:jp)
      if holiday_working
        return business_working_schedule(date)
      else
        return
      end
    end

    # normal bussiness day
    business_working_schedule(date)
  end

  def available_reservation_menus(business_time_range, number_of_customer=1, reservation_id=nil)
    number_of_customer = (number_of_customer.zero? || number_of_customer.nil?) ? 1 : number_of_customer
    start_time = business_time_range.first
    end_time = business_time_range.last
    distance_in_minutes = ((end_time - start_time)/60.0).round

    # shop have custom_schedules(closed temporary) during reservation time.
    if custom_schedules_for_shop(start_time, end_time).exists?
      return Menu.none
    end

    scoped = workable_menus(start_time, end_time, reservation_id).
      where.not("staff_menus.staff_id" => (reserved_staff_ids(start_time, end_time, reservation_id)))

    # Menu with customers need to be afforded by staff
    # staff work for menu0 would be available here.
    no_reservation_except_menu0_menus = scoped.select("menus.*, max(shop_menus.max_seat_number) as max_seat_number").group("menus.id").having("
      CASE
        WHEN menus.min_staffs_number = 1 THEN LEAST(max(staff_menus.max_customers), max(shop_menus.max_seat_number)) >= #{number_of_customer}
        WHEN menus.min_staffs_number > 1 THEN
          count(DISTINCT(staff_menus.staff_id)) >= menus.min_staffs_number AND
          #{number_of_customer} <= MAX(shop_menus.max_seat_number) AND
          (COALESCE((array_agg(staff_menus.max_customers order by staff_menus.max_customers desc))[2], 0) + MAX(staff_menus.max_customers)) >= #{number_of_customer}
        WHEN menus.min_staffs_number = 0 THEN FALSE
        ELSE TRUE
      END
    ")

    reservation_menus = overlap_reservations(start_time, end_time, reservation_id).group_by { |reservation| reservation.menu }.map do |menu, reservations|
      menu_max_seat_number = menu.shop_menus.find_by(shop: self).max_seat_number
      customers_amount_of_reservations = reservations.sum { |reservation| reservation.reservation_customers.count }
      is_enough_seat = menu_max_seat_number >= number_of_customer + customers_amount_of_reservations
      next unless is_enough_seat

      if menu.min_staffs_number == 0
        menu
      elsif menu.min_staffs_number == 1
        if reservations.any? { |reservation|
          reservation.staffs.first.staff_menus.find_by(menu: menu).max_customers >= number_of_customer + reservation.reservation_customers.count
        }
        menu
        end
      elsif menu.min_staffs_number > 1
        if reservations.any? { |reservation|
          staffs_max_customer = reservation.staffs.map { |staff| staff.staff_menus.find_by(menu: menu).max_customers }.min

          staffs_max_customer >= number_of_customer + reservation.reservation_customers.count
        }
        menu
        end
      end
    end.compact

    (no_reservation_except_menu0_menus + reservation_menus +
    no_manpower_menus(business_time_range, number_of_customer, reservation_id)).uniq # staff for menu1, menu2 reservations, still could work for menu0 reservations
  end

  def available_staffs(menu, business_time_range, number_of_customer=1, reservation_id=nil)
    start_time = business_time_range.first
    end_time = business_time_range.last + menu.interval.to_i.minutes

    scoped = menu.staffs.
      joins("LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{id}").
      includes(:staff_menus).
      where.not("staff_menus.staff_id" => (reserved_staff_ids(start_time, end_time, reservation_id) + custom_schedules_staff_ids(start_time, end_time)).uniq)

    scoped = scoped.
      where("business_schedules.full_time = ?", true).
    or(
      scoped.
      where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", business_time_range.first.wday).
      where("business_schedules.start_time::time <= ? and business_schedules.end_time::time >= ?", start_time, end_time)
    )

    # staff work for menu0 would be available here.
    no_reservation_except_menu0_staffs = scoped.select("staffs.*").group("staffs.id")

    reservations = overlap_reservations(start_time, end_time, reservation_id, menu.id)

    menu_max_seat_number = menu.shop_menus.find_by(shop: self).max_seat_number
    customers_amount_of_reservations = reservations.sum { |reservation| reservation.reservation_customers.count }
    is_enough_seat = menu_max_seat_number >= number_of_customer + customers_amount_of_reservations
    return no_reservation_except_menu0_staffs unless is_enough_seat

    reservation_staffs = []
    if menu.min_staffs_number == 0
      # Other reservation(menu1, menu2) staffs still could do this menu0 too.
      all_overlap_reservations = overlap_reservations(start_time, end_time, reservation_id)
      all_overlap_staffs = all_overlap_reservations.map {|reservation| reservation.staffs}.flatten
      reservation_staffs = all_overlap_staffs.find_all { |staff| staff.staff_menus.where(menu: menu).exists? }
    elsif menu.min_staffs_number == 1
      reservation_staffs = reservations.map do |reservation|
        staff = reservation.staffs.first
        staff_max_customer = staff.staff_menus.find_by(menu: menu).max_customers

        if staff_max_customer >= number_of_customer + reservation.reservation_customers.count
          staff
        end
      end.compact.flatten
    elsif menu.min_staffs_number > 1
      reservation_staffs = reservations.map do |reservation|
        staffs_max_customer = reservation.staffs.map { |staff| staff.staff_menus.where(menu: menu).first.max_customers }.min

        if staffs_max_customer >= number_of_customer + reservation.reservation_customers.count
          reservation.staffs
        end
      end.compact.flatten
    end

    (no_reservation_except_menu0_staffs + reservation_staffs).flatten.uniq
  end

  private

  def no_manpower_menus(business_time_range, number_of_customer=1, reservation_id=nil)
    start_time = business_time_range.first
    end_time = business_time_range.last
    distance_in_minutes = ((end_time - start_time)/60.0).round

    if custom_schedules_for_shop(start_time, end_time).exists?
      return Menu.none
    end

    scoped = workable_menus(start_time, end_time, reservation_id).where("menus.min_staffs_number" => 0)

    _no_power_menus = scoped.select("menus.*").group("menus.id")
    _no_power_menus.map do |menu|
      reservations = overlap_reservations(start_time, end_time, reservation_id, menu.id)

      if menu.shop_menus.find_by(shop: self).max_seat_number >= number_of_customer + reservations.sum { |reservation| reservation.reservation_customers.count }
        menu
      end
    end.compact
  end


  def overlap_reservations(start_time, end_time, reservation_id=nil, menu_id=nil)
    scoped = reservations.left_outer_joins(:menu, :reservation_customers, :staffs => :staff_menus).
      where.not(id: reservation_id.presence).
      where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)", end_time, start_time)

    scoped = scoped.where("menus.id = ?", menu_id) if menu_id
    scoped.select("reservations.*").group("reservations.id")
  end

  # staffs had reservations during that time
  def reserved_staff_ids(start_time, end_time, reservation_id=nil)
    # reservation_id.presence: sql don't support reservation_id pass empty string
    # start_time/ready_time checking is >, < not, >=, <= that means we accept reservation is overlap 1 minute

    scoped = ReservationStaff.joins(reservation: :menu).
      where.not(reservation_id: reservation_id.presence).
      where("reservation_staffs.staff_id": staff_ids).
      where.not("menus.min_staffs_number" => 0)

    now = Time.zone.now

    @reserved_staff_ids ||=
      scoped.where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)",end_time, start_time).
      or(
        scoped.where("reservations.shop_id != ?", id).where("reservations.start_time > ? and reservations.end_time <= ?", now.beginning_of_day, now.end_of_day)
      ).
      pluck("DISTINCT staff_id")
  end

  def custom_schedules_staff_ids(start_time, end_time)
    CustomSchedule.
      where(staff_id: staff_ids).
      where("custom_schedules.start_time < ? and custom_schedules.end_time > ?", end_time, start_time).
      pluck("DISTINCT staff_id")
  end

  def custom_schedules_for_shop(start_time, end_time)
    custom_schedules.where("custom_schedules.start_time < ? and custom_schedules.end_time > ?", end_time, start_time)
  end

  def business_schedule(date)
    @business_schedule ||= {}
    @business_schedule[date.wday] ||= business_schedules.for_shop.where(day_of_week: date.wday).opened.first
  end

  def business_working_schedule(date)
    if schedule = business_schedule(date)
      schedule.start_time..schedule.end_time
    end
  end

  def workable_menus(start_time, end_time, reservation_id)
    distance_in_minutes = ((end_time - start_time)/60.0).round

    # menu that has reservation_setting and menu_reservation_setting_rules
    scoped = menus.
      joins(:reservation_setting,
            :menu_reservation_setting_rule).
      joins("LEFT OUTER JOIN staff_menus on staff_menus.menu_id = menus.id
             LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staff_menus.staff_id AND
                                                   business_schedules.shop_id = #{id}
             LEFT OUTER JOIN shop_menu_repeating_dates ON shop_menu_repeating_dates.menu_id = menus.id AND
                                                          shop_menu_repeating_dates.shop_id = #{id}")

    # menus's staffs could not had reservation during reservation time
    # menus time is longer enough
    scoped = scoped.
      where.not("staff_menus.staff_id" => custom_schedules_staff_ids(start_time, end_time)).
      where("minutes <= ?", distance_in_minutes)

    # Menu staffs schedule need to be full_time or work during reservation time
    scoped = scoped.
      where("business_schedules.full_time = ?", true).
    or(
      scoped.
      where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", start_time.wday).
      where("business_schedules.start_time::time <= ? and business_schedules.end_time::time >= ?", start_time, end_time)
    )

    today = Time.zone.now.to_s(:date)

    # Menu need reservation setting to be reserved
    scoped = scoped.where("menu_reservation_setting_rules.start_date <= ?", today)
    scoped = scoped.where("menu_reservation_setting_rules.reservation_type is NULL AND menu_reservation_setting_rules.end_date is NULL").
      or(
        scoped.where("menu_reservation_setting_rules.reservation_type = 'date' AND menu_reservation_setting_rules.end_date >= ?", today)
      ).
      or(
        scoped.where("menu_reservation_setting_rules.reservation_type = 'repeating' AND ? = ANY(shop_menu_repeating_dates.dates)", today)
      )

    scoped = scoped.
      where("reservation_settings.day_type = ?", "business_days").
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time::time <= ? and reservation_settings.end_time::time >= ?)", start_time, end_time).
    or(
      scoped.
      where("reservation_settings.day_type = ? and ? = ANY(reservation_settings.days_of_week)", "weekly", "#{start_time.wday}").
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time::time <= ? and reservation_settings.end_time::time >= ?)", start_time, end_time)
    ).
    or(
      scoped.
      where("reservation_settings.day_type = ? and reservation_settings.day = ?", "monthly", start_time.day).
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time::time <= ? and reservation_settings.end_time::time >= ?)", start_time, end_time)
    ).
    or(
      scoped.
      where("reservation_settings.day_type = ? and reservation_settings.nth_of_week = ? and
             ? = ANY(reservation_settings.days_of_week)", "monthly", start_time.week_of_month, "#{start_time.wday}").
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time::time <= ? and reservation_settings.end_time::time >= ?)", start_time, end_time)
    )
  end
end
