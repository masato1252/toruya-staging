# == Schema Information
#
# Table name: shops
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  name            :string
#  shortname       :string
#  zip_code        :string
#  phone_number    :string
#  email           :string
#  website         :string
#  address         :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  holiday_working :boolean
#

class Shop < ApplicationRecord
  validates :name, presence: true, uniqueness: { scope: :user_id }, format: { without: /\// }
  validates :shortname, presence: true, uniqueness: { scope: :user_id }
  validates :zip_code, presence: true
  validates :phone_number, presence: true
  validates :email, presence: true
  validates :address, presence: true

  has_many :shop_staffs
  has_many :staffs, through: :shop_staffs
  has_many :shop_menus
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
    if custom_close_schedule = custom_schedules.future.where(start_time: date.beginning_of_day..date.end_of_day).order("end_time").last
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
    reservation_id = reservation_id.presence || nil # sql don't support reservation_id pass empty string

    scoped = reservations.where("reservations.start_time <= ? AND reservations.ready_time >= ?", end_time, start_time)

    # when all staffs already have reservations at this time
    if staff_ids.present? && scoped.includes(:staffs).
      map(&:staff_ids).flatten.uniq == staff_ids
      return
    end

    scoped = menus.
      joins(:reservation_settings).
      joins("LEFT OUTER JOIN staff_menus on staff_menus.menu_id = menus.id
             LEFT OUTER JOIN staffs ON staffs.id = staff_menus.staff_id
             LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id
             LEFT OUTER JOIN custom_schedules ON custom_schedules.staff_id = staffs.id
             LEFT OUTER JOIN reservation_staffs ON reservation_staffs.staff_id = staffs.id
             LEFT OUTER JOIN reservations ON reservations.id = reservation_staffs.reservation_id")

    scoped = scoped.
      where("minutes <= ?", distance_in_minutes).
      where("(custom_schedules.start_time is NULL and custom_schedules.end_time is NULL) or (NOT(custom_schedules.start_time <= :end_time AND custom_schedules.end_time >= :start_time))", start_time: start_time, end_time: end_time).
      where("(reservations.start_time is NULL and reservations.end_time is NULL) or
             reservations.id = ? or
             menus.min_staffs_number is NULL or
            (NOT(reservations.start_time <= (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time >= ?))", reservation_id, end_time, start_time)

    scoped = scoped.
      where("staffs.full_time = ?", true).
    or(
      scoped.
      where("business_schedules.business_state = ? and business_schedules.day_of_week = ? ", "opened", business_time_range.first.wday)
    )

    scoped = scoped.
      where("reservation_settings.day_type = ?", "business_days").
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time <= ? and reservation_settings.end_time >= ?)", start_time, end_time).
    or(
      scoped.
      where("reservation_settings.day_type = ? and reservation_settings.day_of_week = ?", "weekly", start_time.wday).
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time <= ? and reservation_settings.end_time >= ?)", start_time, end_time)
    ).
    or(
      scoped.
      where("reservation_settings.day_type = ? and reservation_settings.day = ?", "number_of_day_monthly", start_time.day).
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time <= ? and reservation_settings.end_time >= ?)", start_time, end_time)
    ).
    or(
      scoped.
      where("reservation_settings.day_type = ? and reservation_settings.nth_of_week = ? and
             reservation_settings.day_of_week = ?", "day_of_week_monthly", start_time.week_of_month, start_time.wday).
      where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
             (reservation_settings.start_time <= ? and reservation_settings.end_time >= ?)", start_time, end_time)
    )

    scoped.select("menus.*").group("menus.id").having("
      CASE
        WHEN menus.min_staffs_number = 1 THEN max(staff_menus.max_customers) >= #{number_of_customer}
        WHEN menus.min_staffs_number > 1 THEN count(DISTINCT(staffs.id)) >= menus.min_staffs_number AND #{number_of_customer} <= menus.max_seat_number
        ELSE true
      END
    ")
  end

  def available_staffs(menu, business_time_range, reservation_id=nil)
    start_time = business_time_range.first
    end_time = business_time_range.last + menu.interval.to_i.minutes
    reservation_id = reservation_id.presence || nil # sql don't support reservation_id pass empty string

    # All staffs could do this menu already have reservation
    if menu.staff_ids.present? &&
      reservations.where(menu: menu).where("start_time >= ? and ready_time <= ?", start_time, end_time).includes(:staffs).
      map(&:staff_ids).flatten.uniq == menu.staff_ids
      return
    end

    scoped = menu.staffs.left_outer_joins(:business_schedules, :custom_schedules, :reservations).
      includes(:staff_menus).
      where("(custom_schedules.start_time is NULL and custom_schedules.end_time is NULL) or
             (NOT(custom_schedules.start_time <= ? and custom_schedules.end_time >= ?))", end_time, start_time).
      where("(reservations.start_time is NULL and reservations.end_time is NULL) or
              reservations.id = ? or
             (NOT(reservations.start_time <= ? and reservations.ready_time >= ?))", reservation_id, end_time, start_time)

    scoped.
      where(full_time: true).
    or(
      scoped.
      where("business_schedules.business_state = ? and business_schedules.day_of_week = ? ", "opened", business_time_range.first.wday).
      where("business_schedules.start_time <= ? and business_schedules.end_time >= ?", start_time, end_time)
    )

    scoped.select("staffs.*").group("staffs.id")
  end

  private

  def business_schedule(date)
    @business_schedule ||= {}
    @business_schedule[date.wday] ||= business_schedules.for_shop.where(day_of_week: date.wday).opened.first
  end

  def business_working_schedule(date)
    if schedule = business_schedule(date)
      schedule.start_time..schedule.end_time
    end
  end
end
