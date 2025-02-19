# frozen_string_literal: true
# == Schema Information
#
# Table name: booking_pages
#
#  id                                 :bigint           not null, primary key
#  bookable_restriction_months        :integer          default(3)
#  booking_limit_day                  :integer          default(1), not null
#  booking_limit_hours                :integer          default(0), not null
#  customer_cancel_request            :boolean          default(FALSE)
#  customer_cancel_request_before_day :integer          default(1), not null
#  cut_off_time                       :datetime
#  default_provider                   :string
#  deleted_at                         :datetime
#  draft                              :boolean          default(TRUE), not null
#  end_at                             :datetime
#  event_booking                      :boolean          default(FALSE)
#  greeting                           :text
#  interval                           :integer
#  line_sharing                       :boolean          default(TRUE)
#  multiple_selection                 :boolean          default(FALSE)
#  name                               :string           not null
#  note                               :text
#  online_payment_enabled             :boolean          default(FALSE)
#  overbooking_restriction            :boolean          default(TRUE)
#  payment_option                     :string           default("offline")
#  rich_menu_only                     :boolean          default(FALSE)
#  settings                           :jsonb            not null
#  slug                               :string
#  social_account_skippable           :boolean          default(FALSE), not null
#  specific_booking_start_times       :string           is an Array
#  start_at                           :datetime
#  title                              :string
#  created_at                         :datetime         not null
#  updated_at                         :datetime         not null
#  shop_id                            :bigint           not null
#  user_id                            :bigint           not null
#
# Indexes
#
#  booking_page_index                     (user_id,deleted_at,draft)
#  index_booking_pages_on_rich_menu_only  (rich_menu_only)
#  index_booking_pages_on_shop_id         (shop_id)
#  index_booking_pages_on_slug            (slug) UNIQUE
#

# When booking page limit day is 1, that means you couldn't book today, you have to book one day before the reservation day
# When booking page limit day is 0, that means you could book today
class BookingPage < ApplicationRecord
  include DateTimeAccessor
  date_time_accessor :start_at, :end_at, :cut_off_time, accessor_only: true

  has_many :booking_page_options, -> { order("booking_page_options.position") }
  has_many :booking_page_online_payment_options, -> { where(online_payment_enabled: true).order("booking_page_options.position") }, class_name: "BookingPageOption"
  has_many :booking_options, -> { undeleted }, through: :booking_page_options
  has_many :booking_codes
  has_many :booking_page_special_dates, -> { order(:start_at) }
  has_many :business_schedules
  has_one :product_requirement, as: :requirer

  belongs_to :user
  belongs_to :shop

  scope :active, -> { where(deleted_at: nil) }
  scope :started, -> { active.where(start_at: nil).or(where("booking_pages.start_at < ?", Time.current)) }
  scope :end_yet, -> { where("end_at is NULL or end_at > ?", Time.current) }
  validates :booking_limit_day, numericality: { greater_than_or_equal_to: 0 }
  scope :normal, -> { where(rich_menu_only: false) }
  scope :for_option_in_rich_menu, -> { where(rich_menu_only: true) }

  enum payment_option: {
    offline: "offline",
    online: "online",
    custom: "custom"
  }

  typed_store :settings do |s|
    s.boolean :customer_address_required, default: false, null: false
  end

  def primary_product
    @primary_product ||= booking_options.order(amount_cents: :asc).first
  end

  def product_name
    @product_name ||= ActionController::Base.helpers.strip_tags(primary_product&.display_name.presence || primary_product&.name.presence || name)
  end

  def product_price
    @product_price ||= primary_product&.amount
  end

  def product_price_text
    @product_price_text ||= primary_product&.price_text
  end

  def start_time
    start_at || created_at
  end

  def start_time_text
    start_at ? I18n.l(start_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_now")
  end

  def end_time_text
    end_at ? I18n.l(end_at, format: :long_date_with_wday) : I18n.t("settings.booking_page.form.sale_forever")
  end

  def available_booking_start_date
    default_start_date = Subscription.today.advance(days: booking_limit_day)

    if start_at
      [start_at.to_date, default_start_date].max
    else
      default_start_date
    end
  end

  def available_booking_end_date
    # No bookable_restriction_months nil means no restriction, use 100 months to represent
    default_booking_end_date = Subscription.today.advance(months: bookable_restriction_months || 100)

    if end_at
      [end_at.to_date, default_booking_end_date].min
    else
      default_booking_end_date
    end
  end

  def started?
    Time.zone.now >= start_time
  end

  def ended?
    (end_at && Time.zone.now > end_at) || (booking_page_special_dates.exists? && available_booking_start_date > booking_page_special_dates.last.start_at) || deleted_at.present? || (cut_off_time && Time.current > cut_off_time)
  end

  def booking_type
    @booking_type ||=
      if event_booking
        "event_booking"
      elsif booking_page_special_dates.exists?
        "only_special_dates_booking"
      elsif business_schedules.exists?
        "business_schedules_booking"
      else
        "any"
      end
  end

  # XXX: only used for demo
  def message_template_variables(user)
    Templates::ReservationVariables.run!(
      receiver: user,
      shop: shop,
      start_time: Time.current,
      end_time: Time.current.advance(hours: 1),
      meeting_url: ApplicationController.helpers.data_by_locale(:official_site_url),
      product_name: booking_options.first&.display_name.presence || I18n.t("common.menu"),
      booking_page_url: Rails.application.routes.url_helpers.booking_page_url(slug),
      booking_info_url: ApplicationController.helpers.data_by_locale(:official_site_url)
    )
  end

  def payment_solution
    Users::PaymentSolution.run!(user: user, provider: payment_provider)
  end

  def payment_provider
    default_provider.presence || user.payment_provider&.provider
  end

  def requirement_customers
    product_requirement.requirement&.available_customers || []
  end

  def requirement_online_service
    product_requirement&.requirement
  end
end
