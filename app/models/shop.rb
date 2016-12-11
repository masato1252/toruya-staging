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

    # menu that has reservation_setting and menu_reservation_setting_rules
    scoped = menus.
      joins(:reservation_setting,
            :menu_reservation_setting_rule).
      joins("LEFT OUTER JOIN staff_menus on staff_menus.menu_id = menus.id
             LEFT OUTER JOIN staffs ON staffs.id = staff_menus.staff_id
             LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{id}
             LEFT OUTER JOIN custom_schedules ON custom_schedules.staff_id = staffs.id AND custom_schedules.shop_id = #{id}
             LEFT OUTER JOIN shop_menu_repeating_dates ON shop_menu_repeating_dates.menu_id = menus.id AND
                                                          shop_menu_repeating_dates.shop_id = #{id}")

    # menus's staffs could not had reservation during reservation time
    # menus time is longer enough
    # shop doesn't have custom_schedules(closed temporary) during reservation time.
    scoped = scoped.
      where.not("staff_menus.staff_id" => reserved_staff_ids(start_time, end_time, reservation_id)).
      where("minutes <= ?", distance_in_minutes).
      where("(custom_schedules.start_time is NULL and custom_schedules.end_time is NULL) or
             (NOT(custom_schedules.start_time <= :end_time AND custom_schedules.end_time >= :start_time))",
             start_time: start_time, end_time: end_time)

    # Menu staffs schedule need to be full_time or work during reservation time
    scoped = scoped.
      where("business_schedules.full_time = ?", true).
    or(
      scoped.
      where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", business_time_range.first.wday).
      where("business_schedules.start_time <= ? and business_schedules.end_time >= ?", start_time, end_time)
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

    # Menu with customers need to be afforded by staff
    scoped.select("menus.*").group("menus.id").having("
      CASE
        WHEN menus.min_staffs_number = 1 THEN max(staff_menus.max_customers) >= #{number_of_customer}
        WHEN menus.min_staffs_number > 1 THEN count(DISTINCT(staffs.id)) >= menus.min_staffs_number AND #{number_of_customer} <= menus.max_seat_number AND sum(staff_menus.max_customers) >= #{number_of_customer}
        ELSE true
      END
    ")
  end

  def available_staffs(menu, business_time_range, reservation_id=nil)
    start_time = business_time_range.first
    end_time = business_time_range.last + menu.interval.to_i.minutes

    # If this menu doesn't take any man power, then it could be assigned to anyone
    unless menu.min_staffs_number
      return menu.staffs
    end

    scoped = menu.staffs.
      joins("LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{id}
             LEFT OUTER JOIN custom_schedules ON custom_schedules.staff_id = staffs.id AND custom_schedules.shop_id = #{id}").
      includes(:staff_menus).
      where.not("staff_menus.staff_id" => reserved_staff_ids(start_time, end_time, reservation_id)).
      where("(custom_schedules.start_time is NULL and custom_schedules.end_time is NULL) or
             (NOT(custom_schedules.start_time <= ? and custom_schedules.end_time >= ?))", end_time, start_time)

    scoped = scoped.
      where("business_schedules.full_time = ?", true).
    or(
      scoped.
      where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", business_time_range.first.wday).
      where("business_schedules.start_time::time <= ? and business_schedules.end_time::time >= ?", start_time, end_time)
    )

    scoped.select("staffs.*").group("staffs.id")
  end

  # No manpower menus are available for anytime, just valid staffs work during that time.
  def no_manpower_menus(business_time_range)
    start_time = business_time_range.first
    end_time = business_time_range.last

    scoped = menus.
      where("menus.min_staffs_number" => nil).
      joins(:staffs).
      joins("LEFT OUTER JOIN business_schedules ON business_schedules.staff_id = staffs.id AND business_schedules.shop_id = #{id}
             LEFT OUTER JOIN custom_schedules ON custom_schedules.staff_id = staffs.id AND custom_schedules.shop_id = #{id}").
      where("(custom_schedules.start_time is NULL and custom_schedules.end_time is NULL) or
             (NOT(custom_schedules.start_time <= ? and custom_schedules.end_time >= ?))", end_time, start_time)

    scoped = scoped.
      where("business_schedules.full_time = ?", true).
    or(
      scoped.
      where("business_schedules.business_state = ? and business_schedules.day_of_week = ?", "opened", business_time_range.first.wday).
      where("business_schedules.start_time::time <= ? and business_schedules.end_time::time >= ?", start_time, end_time)
    )

    scoped.select("menus.*").group("menus.id")
  end

  private

  # staffs had reservations during that time
  def reserved_staff_ids(start_time, end_time, reservation_id=nil)
    # reservation_id.presence: sql don't support reservation_id pass empty string
    # start_time/ready_time checking is >, < not, >=, <= that means we accept reservation is overlap 1 minute

    @reserved_staff_ids ||= ReservationStaff.
      joins(reservation: :menu).
      where.not(reservation_id: reservation_id.presence).
      where.not("menus.min_staffs_number": nil).
      where("reservation_staffs.staff_id": staff_ids).
      where("(reservations.start_time < (TIMESTAMP ? + (INTERVAL '1 min' * menus.interval)) and reservations.ready_time > ?)",
          end_time, start_time).
      pluck(:staff_id).uniq
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
end
