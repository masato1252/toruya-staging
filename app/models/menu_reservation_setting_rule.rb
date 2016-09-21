# == Schema Information
#
# Table name: menu_reservation_setting_rules
#
#  id               :integer          not null, primary key
#  menu_id          :integer
#  reservation_type :string
#  start_date       :date
#  end_date         :date
#  repeats          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class MenuReservationSettingRule < ApplicationRecord
  TYPES = %w(date repeating)
  belongs_to :menu

  validates :start_date, presence: true
  validates :reservation_type, inclusion: { in: TYPES }, allow_blank: true

  def repeating_dates
    case menu.reservation_setting.day_type
    when "business_days"
      if menu.shops.present?
        menu.shops.map do |shop|
          business_days_repeating_dates_calculator(shop)
        end
      else
        business_days_repeating_dates_calculator(nil)
      end
    when "weekly"
      if menu.shops.present?
        menu.shops.map do |shop|
          weekly_repeating_dates_calculator(shop)
        end
      else
        weekly_repeating_dates_calculator(nil)
      end
    when "monthly"
      if menu.reservation_setting.number_of_day_monthly?
        if menu.shops.present?
          menu.shops.map do |shop|
            number_of_day_monthly_repeating_dates_calculator(shop)
          end
        else
          number_of_day_monthly_repeating_dates_calculator(nil)
        end
      else
        # days_of_week_monthly
      end
    end
  end

  private

  def get_next_day(date, day_of_week)
    date + ((day_of_week - date.wday) % 7)
  end

  def business_days_repeating_dates_calculator(shop)
    beginning_date = start_date
    business_schedules_exist = shop && shop.business_schedules.for_shop.exists?
    n = 0

    repeat_dates = repeats.times.map do
      begin
        matched_date = beginning_date.advance(days: n)
        n += 1
      end until (business_schedules_exist ? shop.available_time(matched_date) : matched_date.working_day?)

      matched_date
    end

    {
      shop: shop,
      dates: repeat_dates
    }
  end

  def weekly_repeating_dates_calculator(shop)
    beginning_date = start_date
    setting_days_of_week = menu.reservation_setting.days_of_week.map(&:to_i)
    business_schedules_exist = shop && shop.business_schedules.for_shop.exists?
    routine = setting_days_of_week.count

    first_matched_date = setting_days_of_week.map do |day_of_week|
      get_next_day(beginning_date, day_of_week)
    end.min

    nth_match_day = setting_days_of_week.index(first_matched_date.wday)

    matched_date = first_matched_date

    repeat_dates = repeats.times.map do
      begin
        matched_date = get_next_day(matched_date, setting_days_of_week.at(nth_match_day%routine))
        nth_match_day += 1
      end until (business_schedules_exist ? shop.available_time(matched_date) : matched_date.working_day?)

      matched_date
    end

    {
      shop: shop,
      dates: repeat_dates
    }
  end

  def number_of_day_monthly_repeating_dates_calculator(shop)
    repeat_day = menu.reservation_setting.day
    beginning_date = start_date
    business_schedules_exist = shop && shop.business_schedules.for_shop.exists?
    init_advance_month = beginning_date.day > repeat_day ? 1 : 0
    n = 0

    repeat_dates = repeats.times.map do
      begin
        matched_date = Date.new(beginning_date.year, beginning_date.month, repeat_day).advance(months: init_advance_month + n)
        n += 1
      end until (business_schedules_exist ? shop.available_time(matched_date) :  matched_date.working_day?)

      matched_date
    end

    {
      shop: shop,
      dates: repeat_dates
    }
  end
end
