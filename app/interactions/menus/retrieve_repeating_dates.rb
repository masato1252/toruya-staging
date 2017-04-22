module Menus
  class RetrieveRepeatingDates < ActiveInteraction::Base
    DAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"].freeze
    integer :reservation_setting_id
    array :shop_ids, default: []
    integer :repeats
    date :start_date

    def execute
      shops = shop_ids.present? ? Shop.where(id: shop_ids) : [nil]

      case reservation_setting.day_type
      when "business_days"
        shops.map do |shop|
          business_days_repeating_dates_calculator(shop)
        end
      when "weekly"
        shops.map do |shop|
          weekly_repeating_dates_calculator(shop)
        end
      when "monthly"
        if reservation_setting.number_of_day_monthly?
          shops.map do |shop|
            number_of_day_monthly_repeating_dates_calculator(shop)
          end
        else
          # days_of_week_monthly
          shops.map do |shop|
            days_of_week_monthly_repeating_dates_calculator(shop)
          end
        end
      end
    end

    private

    def get_next_day(date, day_of_week)
      date + ((day_of_week - date.wday) % 7)
    end

    def business_days_repeating_dates_calculator(shop=nil)
      beginning_date = start_date
      business_schedules_exist = shop && shop.business_schedules.for_shop.exists?
      n = 0

      repeat_dates = repeats.times.map do
        begin
          matched_date = beginning_date.advance(days: n)
          n += 1
        end until (business_schedules_exist ? Reservable::Time.run(shop: shop, date: matched_date).valid? : matched_date.working_day? && !matched_date.holiday?(:jp))

        matched_date
      end

      {
        shop: shop,
        dates: repeat_dates
      }
    end

    def weekly_repeating_dates_calculator(shop=nil)
      beginning_date = start_date
      setting_days_of_week = reservation_setting.days_of_week.map(&:to_i)
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
        end until (business_schedules_exist ? Reservable::Time.run(shop: shop, date: matched_date).valid? : matched_date.working_day? && !matched_date.holiday?(:jp))

        matched_date
      end

      {
        shop: shop,
        dates: repeat_dates
      }
    end

    def number_of_day_monthly_repeating_dates_calculator(shop=nil)
      repeat_day = reservation_setting.day
      beginning_date = start_date
      business_schedules_exist = shop && shop.business_schedules.for_shop.exists?
      init_advance_month = beginning_date.day > repeat_day ? 1 : 0
      n = 0

      repeat_dates = repeats.times.map do
        begin
          matched_date = Date.new(beginning_date.year, beginning_date.month, repeat_day).advance(months: init_advance_month + n)
          n += 1
        end until (business_schedules_exist ? Reservable::Time.run(shop: shop, date: matched_date).valid? :  matched_date.working_day? && !matched_date.holiday?(:jp))

        matched_date
      end

      {
        shop: shop,
        dates: repeat_dates
      }
    end

    def days_of_week_monthly_repeating_dates_calculator(shop=nil)
      setting_days_of_week = reservation_setting.days_of_week.map(&:to_i)
      business_schedules_exist = shop && shop.business_schedules.for_shop.exists?
      routine = setting_days_of_week.count

      candidate_dates = []

      matched_date = start_date

      begin
        candidate_dates << setting_days_of_week.map do |day_of_week|
          # (2016, 10, 1).get_next_day_of_week("monday", 3)
          matched_date_number = matched_date.send("all_#{DAYS.at(day_of_week)}s_in_month")[reservation_setting.nth_of_week - 1]
          matched_date.change(day: matched_date_number) if matched_date_number
        end.compact.find_all do |date|
          date >= start_date && (business_schedules_exist ? Reservable::Time.run(shop: shop, date: date).valid? : date.working_day? && !date.holiday?(:jp))
        end

        matched_date = (candidate_dates.flatten.last || matched_date).next_month.beginning_of_month
      end until candidate_dates.flatten.size >= repeats

      {
        shop: shop,
        dates: candidate_dates.flatten.sort.first(repeats)
      }
    end

    def reservation_setting
      @reservation_setting ||= ReservationSetting.find_by(id: reservation_setting_id)
    end
  end
end
