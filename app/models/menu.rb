# frozen_string_literal: true
# == Schema Information
#
# Table name: menus
#
#  id                :integer          not null, primary key
#  user_id           :integer          not null
#  name              :string           not null
#  short_name        :string
#  minutes           :integer
#  interval          :integer
#  min_staffs_number :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  deleted_at        :datetime
#  online            :boolean          default(FALSE)
#
# Indexes
#
#  index_menus_on_user_id_and_deleted_at  (user_id,deleted_at)
#

class Menu < ApplicationRecord
  NO_MAN_POWER_STAFF_NUMBER = 0

  include ReservationChecking
  include Helpers

  default_value_for :minutes, 60
  default_value_for :min_staffs_number, 1
  default_value_for :interval, 0

  validates :name, presence: true
  validates :minutes, presence: true
  validates :min_staffs_number, numericality: { greater_than_or_equal_to: 0 }

  has_many :staff_menus, inverse_of: :menu, dependent: :destroy
  has_many :menu_staffs, inverse_of: :menu, dependent: :destroy, class_name: "StaffMenu"
  has_many :staffs, through: :staff_menus
  has_many :active_staffs, ->{ Staff.active.references(:staffs) }, through: :staff_menus, class_name: "Staff", source: :staff
  has_many :shop_menus, inverse_of: :menu, dependent: :destroy
  has_many :shops, -> { active }, through: :shop_menus
  has_many :menu_categories, dependent: :destroy
  has_many :categories, through: :menu_categories
  has_many :reservations
  has_many :shop_menu_repeating_dates, dependent: :destroy
  has_many :booking_option_menus
  has_many :booking_options, -> { undeleted }, through: :booking_option_menus

  has_one :reservation_setting_menu, dependent: :destroy
  has_one :reservation_setting, through: :reservation_setting_menu
  has_one :menu_reservation_setting_rule, dependent: :destroy

  belongs_to :user

  accepts_nested_attributes_for :staff_menus, allow_destroy: true, reject_if: :reject_staffs
  accepts_nested_attributes_for :menu_staffs, allow_destroy: true, reject_if: :reject_staffs
  accepts_nested_attributes_for :shop_menus, allow_destroy: true, reject_if: :reject_shops

  scope :active, -> { where(deleted_at: nil) }

  def self.workable_scoped(shop: , start_time:, end_time: )
    today = ::Time.zone.now.to_fs(:date)

    workable_menus_scoped = all.
        joins(:reservation_setting,
              :menu_reservation_setting_rule).
        joins("LEFT OUTER JOIN shop_menu_repeating_dates ON shop_menu_repeating_dates.menu_id = menus.id AND
                                                            shop_menu_repeating_dates.shop_id = #{shop.id}")

      workable_menus_scoped = workable_menus_scoped.where("menu_reservation_setting_rules.start_date <= ?", today)

      workable_menus_scoped = workable_menus_scoped.
        where("menu_reservation_setting_rules.reservation_type is NULL AND
               menu_reservation_setting_rules.end_date is NULL").
        or(workable_menus_scoped.
            where("menu_reservation_setting_rules.reservation_type = 'date' AND
                   menu_reservation_setting_rules.end_date >= ?", today)
        ).
        or(workable_menus_scoped.
            where("menu_reservation_setting_rules.reservation_type = 'repeating' AND
                   ? = ANY(shop_menu_repeating_dates.dates)", today)
        )

      workable_menus_scoped = workable_menus_scoped.
        where("(reservation_settings.start_time is NULL and reservation_settings.end_time is NULL) or
               ((reservation_settings.start_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time <= ? and
                (reservation_settings.end_time + '#{::Time.zone.now.utc_offset} seconds'::INTERVAL)::time >= ?)",
                start_time.to_fs(:time), end_time.to_fs(:time))

      workable_menus_scoped = workable_menus_scoped.where("reservation_settings.day_type = ?", "business_days").
      or(
        workable_menus_scoped.
          where("reservation_settings.day_type = ? and ? = ANY(reservation_settings.days_of_week)", "weekly", "#{start_time.wday}")
      ).
      or(
        workable_menus_scoped.where("reservation_settings.day_type = ? and reservation_settings.day = ?", "monthly", start_time.day)
      ).
      or(
        workable_menus_scoped.
          where("reservation_settings.day_type = ? and reservation_settings.nth_of_week = ? and
               ? = ANY(reservation_settings.days_of_week)", "monthly", start_time.week_of_month, "#{start_time.wday}")
      )
  end

  def no_manpower?
    min_staffs_number == NO_MAN_POWER_STAFF_NUMBER
  end

  def exclusive_booking_options
    BookingOption.joins(:booking_option_menus)
                 .where(delete_at: nil)
                 .group('booking_options.id')
                 .having('COUNT(DISTINCT booking_option_menus.menu_id) = 1')
                 .having('bool_and(booking_option_menus.menu_id = ?)', self.id)
  end

  private

  def reject_staffs(attributes)
    attributes["id"].blank? && attributes["staff_id"].blank?
  end

  def reject_shops(attributes)
    attributes["id"].blank? && attributes["shop_id"].blank?
  end
end
