# frozen_string_literal: true
# == Schema Information
#
# Table name: subscriptions
#
#  id                 :bigint(8)        not null, primary key
#  plan_id            :bigint(8)
#  next_plan_id       :integer
#  user_id            :bigint(8)
#  stripe_customer_id :string
#  recurring_day      :integer
#  expired_date       :date
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  rank               :integer          default(0)
#  trial_days         :integer
#
# Indexes
#
#  index_subscriptions_on_plan_id  (plan_id)
#  index_subscriptions_on_user_id  (user_id) UNIQUE
#

class Subscription < ApplicationRecord
  FREE_PLAN_ID = 1
  REFUNDABLE_DAYS = 8

  belongs_to :plan, required: false
  belongs_to :next_plan, class_name: "Plan", required: false
  belongs_to :user

  validates :user_id, uniqueness: true

  scope :recurring_chargeable_at, ->(date) {
    return none if date < today

    # Exclude when creation and query date are the same date
    scope = where("DATE(created_at) != ?", date)

    if date == date.end_of_month
      scope.where("recurring_day >= ?", date.day)
    else
      scope.where(recurring_day: date.day)
    end
  }

  scope :chargeable, -> (date) {
    where("expired_date <= ?", date)
  }

  scope :charge_required, -> { where.not(plan_id: FREE_PLAN_ID) }

  def self.today
    Date.jp_today
  end

  def charge_required
    plan_id != FREE_PLAN_ID
  end

  def current_plan
    @current_plan ||= active? ? plan : Plan.free_level.take
  end

  def in_paid_plan
    charge_required && expired_date && expired_date >= self.class.today
  end

  def active?
    plan_id == FREE_PLAN_ID || expired_date >= self.class.today
  end

  def chargeable?
    expired_date <= self.class.today
  end

  def refundable?
    first_charge && first_charge.completed? && first_charge.created_at >= REFUNDABLE_DAYS.days.ago
  end

  def first_charge
    @first_charge ||= user.subscription_charges.finished.manual.first
  end

  def set_recurring_day
    self.recurring_day = self.class.today.day
  end

  def set_expire_date
    self.expired_date = next_charge_date
  end

  def expire
    self.expired_date = self.class.today.yesterday
  end

  def next_period
    expired_date..recurring_date(expired_date.year, expired_date.next_month.month)
  end

  private

  def next_charge_date
    if user.subscription_charges.last_completed
      scheduled_recurring_date
    else
      self.class.today
    end
  end

  def recurring_date(year, month)
    end_day_of_month = Date.new(year, month).end_of_month.day

    Date.new(year, month, [end_day_of_month, recurring_day].min)
  end

  def scheduled_recurring_date
    date =
      if Plan::ANNUAL_CHARGE_PLANS.include?(plan.level)
        user.subscription_charges.last_completed.charge_date.next_year
      else
        # XXX: If before subscription expired, # we did charged, then extend the subscription expired date further, not from the charge date
        last_charged_record = user.subscription_charges.where.not(expired_date: nil).last_completed
        current_charged_record = user.subscription_charges.last_completed

        if last_charged_record && last_charged_record.expired_date > Date.today
          last_charged_record.expired_date.next_month
        else
          current_charged_record.charge_date.next_month
        end
      end

    recurring_date(date.year, date.month)
  end
end
