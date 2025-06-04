# frozen_string_literal: true
# == Schema Information
#
# Table name: reservations
#
#  id                      :integer          not null, primary key
#  aasm_state              :string           not null
#  count_of_customers      :integer          default(0)
#  deleted_at              :datetime
#  end_time                :datetime         not null
#  meeting_url             :string
#  memo                    :text
#  online                  :boolean          default(FALSE)
#  prepare_time            :datetime
#  ready_time              :datetime         not null
#  start_time              :datetime         not null
#  with_warnings           :boolean          default(FALSE), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  by_staff_id             :integer
#  menu_id                 :integer
#  shop_id                 :integer          not null
#  survey_activity_id      :integer
#  survey_activity_slot_id :integer
#  user_id                 :integer
#
# Indexes
#
#  idx_reservations_on_activity_and_slot  (survey_activity_id,survey_activity_slot_id)
#  reservation_query_index                (user_id,shop_id,aasm_state,menu_id,start_time,ready_time)
#  reservation_user_shop_index            (user_id,shop_id,deleted_at)
#

# ready_time is end_time + menu.interval
require "message_encryptor"

class Reservation < ApplicationRecord
  include DateTimeAccessor

  has_paper_trail on: [:update]
  date_time_accessor :start_time, :end_time, accessor_only: true

  include AASM
  BEFORE_CHECKED_IN_STATES = %w(pending reserved canceled).freeze
  AFTER_CHECKED_IN_STATES = %w(checked_in checked_out noshow).freeze
  REMINDERABLE_STATES = %w(reserved checked_out checked_in)

  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_larger_than_start_time

  belongs_to :user
  belongs_to :shop
  belongs_to :by_staff, class_name: "Staff", required: false
  # has_one :reservation_booking_option
  # has_one :booking_option, through: :reservation_booking_option
  belongs_to :survey_activity, optional: true
  belongs_to :survey_activity_slot, optional: true
  has_many :reservation_staffs, dependent: :destroy
  has_many :reservation_menus, -> { order("position") }, dependent: :destroy
  has_many :menus, through: :reservation_menus, dependent: :destroy
  has_many :staffs, through: :reservation_staffs
  has_many :reservation_customers, dependent: :destroy
  has_many :active_reservation_customers, -> { active }, dependent: :destroy, class_name: "ReservationCustomer"
  has_many :customers, through: :active_reservation_customers

  scope :in_date, ->(date) { where("start_time >= ? AND start_time <= ?", date.beginning_of_day, date.end_of_day) }
  scope :in_month, ->(date) { where("start_time >= ? AND start_time <= ?", date.beginning_of_month, date.end_of_month) }
  scope :future, -> { where("start_time > ?", Time.current) }
  scope :past, -> { where("start_time <= ?", Time.current) }
  scope :uncanceled, -> { where(aasm_state: %w(pending reserved noshow checked_in checked_out)).active }
  scope :active, -> { where(deleted_at: nil) }
  scope :reminderable, -> { where(aasm_state: REMINDERABLE_STATES) }

  aasm :whiny_transitions => false do
    state :pending, initial: true
    state :reserved, :noshow, :checked_in, :checked_out, :canceled

    event :pend do
      transitions from: [:checked_out, :checked_in, :reserved, :noshow, :canceled], to: :pending
    end

    event :accept do
      transitions from: [:canceled, :pending], to: :reserved
    end

    event :check_in do
      transitions from: [:checked_out, :reserved, :noshow], to: :checked_in
    end

    event :check_out do
      transitions from: [:checked_in, :reserved, :noshow], to: :checked_out
    end

    event :cancel do
      transitions from: [:pending, :reserved, :noshow, :checked_in, :checked_out, :reserved], to: :canceled
    end
  end

  def for_staff(staff)
    reservation_staffs.find_by(staff: staff)
  end

  def acceptable_by_staff?(staff)
    may_accept? && (
      reservation_staffs.loaded? ? reservation_staffs.find { |rs| rs.staff_id == staff.id }&.pending? : for_staff(staff)&.pending?
    )
  end

  def responsible_by_staff?(staff)
    return false if !staff
    reservation_staffs.loaded? ? reservation_staffs.find { |rs| rs.staff_id == staff.id } : for_staff(staff)
  end

  def accepted_by_all_staffs?
    !reservation_staffs.pending.exists?
  end

  def accepted_all_customers?
    !reservation_customers.pending.exists?
  end

  def try_accept
    if accepted_by_all_staffs?
      self.accept
    else reserved?
      self.pend
    end
  end

  ACTIONS = {
    "checked_in" => ["check_out", "cancel", "edit"],
    "reserved" => ["check_in", "pend", "cancel", "edit"],
    "noshow" => ["check_in", "pend"],
    "pending" => ["accept", "cancel", "edit"],
    "checked_out" => ["recheck_in", "pend", "cancel", "edit"],
    "canceled" => ["accept", "edit"]
  }.freeze

  def actions
    ACTIONS[aasm_state]
  end

  def message_template_variables(customer)
    reservation_customer = ReservationCustomer.find_by(reservation: self, customer: customer)

    variables = Templates::ReservationVariables.run!(
      receiver: customer,
      shop: shop,
      start_time: start_time,
      end_time: end_time,
      meeting_url: meeting_url,
      product_name: reservation_customer&.booking_options&.any? ? reservation_customer.booking_options.map(&:present_name).join(", ") : products_sentence,
      booking_page_url: reservation_customer&.booking_page ? Rails.application.routes.url_helpers.booking_page_url(reservation_customer.booking_page.slug, last_booking_option_ids: reservation_customer.booking_option_ids.join(",")) : "",
      booking_info_url: reservation_customer ? reservation_customer.booking_info_url : "",
      reservation_popup_url: reservation_popup_url
    )

    if survey_activity
      variables.merge!(survey_activity.survey.message_template_variables(customer, reservation_customer))
    else
      variables
    end
  end

  def reservation_popup_url
  end

  def notifiable?
    deleted_at.nil?
  end

  def reminderable?
    REMINDERABLE_STATES.include?(aasm_state)
  end

  def remind_customer?(customer)
    notifiable? && reservation_customers.where(customer: customer, state: :accepted).exists?
  end

  def booking_time
    Time.use_zone(user.timezone) do
      "#{I18n.l(start_time, format: :long_date_with_wday)} ~ #{I18n.l(end_time, format: :time_only)}"
    end
  end

  def menus_sentence
    menus.map(&:display_name).join(", ").presence || survey_activity&.name
  end
  alias_method :products_sentence, :menus_sentence

  def from_activity?
    survey_activity_id.present?
  end

  def dates
    (start_time.to_date..end_time.to_date).to_a
  end

  private

  def end_time_larger_than_start_time
    if start_time && end_time
      end_time > start_time
    end
  end
end
