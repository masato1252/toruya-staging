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

  has_many :staffs
  has_many :menus
  has_many :business_schedules
  has_many :custom_schedules
  has_many :customers
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

  private

  def business_schedule(date)
    @business_schedule ||= {}
    @business_schedule[date.wday] ||= business_schedules.where(days_of_week: date.wday).opened.first
  end

  def business_working_schedule(date)
    if schedule = business_schedule(date)
      schedule.start_time..schedule.end_time
    end
  end
end
