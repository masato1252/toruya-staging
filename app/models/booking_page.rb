# frozen_string_literal: true
# == Schema Information
#
# Table name: booking_pages
#
#  id                      :bigint(8)        not null, primary key
#  user_id                 :bigint(8)        not null
#  shop_id                 :bigint(8)        not null
#  name                    :string           not null
#  title                   :string
#  greeting                :text
#  note                    :text
#  interval                :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  start_at                :datetime
#  end_at                  :datetime
#  overbooking_restriction :boolean          default(TRUE)
#  draft                   :boolean          default(TRUE), not null
#  booking_limit_day       :integer          default(1), not null
#  line_sharing            :boolean          default(TRUE)
#  slug                    :string
#  deleted_at              :datetime
#
# Indexes
#
#  booking_page_index              (user_id,deleted_at,draft)
#  index_booking_pages_on_shop_id  (shop_id)
#  index_booking_pages_on_slug     (slug) UNIQUE
#

# When booking page limit day is 1, that means you couldn't book today, you have to book one day before the reservation day
# When booking page limit day is 0, that means you could book today
class BookingPage < ApplicationRecord
  include DateTimeAccessor
  date_time_accessor :start_at, :end_at, accessor_only: true

  has_many :booking_page_options
  has_many :booking_options, through: :booking_page_options
  has_many :booking_codes
  has_many :booking_page_special_dates, -> { order(:start_at) }

  belongs_to :user
  belongs_to :shop

  scope :active, -> { where(deleted_at: nil) }
  scope :started, -> { active.where(start_at: nil).or(where("booking_pages.start_at < ?", Time.current)) }
  validates :booking_limit_day, numericality: { greater_than_or_equal_to: 0 }

  def primary_product
    @primary_product ||= booking_options.order(amount_cents: :asc).first
  end

  def product_name
    @product_name ||= primary_product&.display_name.presence || primary_product&.name.presence || name
  end

  def product_price
    @product_price ||= primary_product&.amount
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
    Subscription.today.advance(days: booking_limit_day)
  end

  def started?
    Time.zone.now >= start_time && booking_options.active.exists?
  end

  def ended?
    (end_at && Time.zone.now > end_at) || (booking_page_special_dates.exists? && available_booking_start_date > booking_page_special_dates.last.start_at) || deleted_at.present?
  end

  def only_specail_dates_booking?
    booking_page_special_dates.exists?
  end
end
