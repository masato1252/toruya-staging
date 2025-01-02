# frozen_string_literal: true
# == Schema Information
#
# Table name: sale_pages
#
#  id                           :bigint           not null, primary key
#  content                      :json
#  deleted_at                   :datetime
#  draft                        :boolean          default(FALSE)
#  flow                         :json
#  internal_name                :string
#  introduction_video_url       :string
#  map_public                   :boolean          default(FALSE)
#  normal_price_amount_cents    :decimal(, )
#  product_type                 :string           not null
#  published                    :boolean          default(TRUE)
#  quantity                     :integer
#  recurring_prices             :jsonb
#  sale_template_variables      :json
#  sections_context             :jsonb
#  selling_end_at               :datetime
#  selling_multiple_times_price :string           default([]), is an Array
#  selling_price_amount_cents   :decimal(, )
#  selling_start_at             :datetime
#  slug                         :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  product_id                   :bigint           not null
#  sale_template_id             :bigint
#  staff_id                     :bigint
#  user_id                      :bigint
#
# Indexes
#
#  index_sale_pages_on_product_type_and_product_id  (product_type,product_id)
#  index_sale_pages_on_sale_template_id             (sale_template_id)
#  index_sale_pages_on_slug                         (slug) UNIQUE
#  index_sale_pages_on_staff_id                     (staff_id)
#  sale_page_index                                  (user_id,deleted_at)
#

require "thumbnail_of_video"

# selling_multiple_times_price: [1000, 1000, 1000]
# recurring_prices: [
#   {
#     interval: 'month',
#     amount: 2000,
#     stripe_price_id: "price_xxx",
#     active: true
#   },
#   {
#     interval: 'year',
#     amount: 2000,
#     stripe_price_id: "price_xeexx",
#     active: true
#   }
# ]

class SalePage < ApplicationRecord
  PAYMENTS = {
    one_time: "one_time",
    multiple_times: "multiple_times",
    free: "free",
    month: "month",
    year: "year",
    bundler: "bundler",
    assignment: "assignment"
  }.freeze

  belongs_to :product, polymorphic: true # OnlineService/BookingPage
  belongs_to :staff, optional: true
  belongs_to :sale_template
  belongs_to :user

  has_one_attached :picture # content picture
  has_many_attached :customer_pictures

  scope :active, -> { where(deleted_at: nil) }
  scope :end_yet, -> { where("selling_end_at is NULL or selling_end_at > ?", Time.current) }
  scope :for_online_service, -> { where(product_type: "OnlineService") }
  scope :with_draft, -> { where(draft: true) }
  validates :product_type, inclusion: { in: %w[OnlineService BookingPage] }

  def selling_price_amount
    Money.new(selling_price_amount_cents, user.currency) if selling_price_amount_cents.present?
  end

  def normal_price_amount
    Money.new(normal_price_amount_cents, user.currency) if normal_price_amount_cents.present?
  end

  def free?
    (selling_price_amount_cents.nil? || selling_price_amount.zero?) && selling_multiple_times_price.blank? && !recurring? && !external?
  end

  def external?
    !is_booking_page? && product.external?
  end

  def recurring?
    recurring_prices.present?
  end

  def is_booking_page?
    product_type == "BookingPage"
  end

  def internal_sale_name
    internal_name || internal_product_name
  end

  def internal_product_name
    product.try(:internal_name)&.presence || product.try(:display_name)&.presence || product&.name
  end

  def product_name
    product&.name
  end

  def selling_prices_text
    [selling_price_text, selling_multiple_times_price_text, recurring_prices_text].compact.join(", ").presence || I18n.t("common.free_price")
  end

  def selling_price_text
    if user.currency == "JPY"
      selling_price_amount&.format(:ja_default_format)
    else
      selling_price_amount&.format
    end
  end

  def selling_multiple_times_price_text
    if selling_multiple_times_price.present?
      times = selling_multiple_times_price.size
      amount = selling_multiple_times_price.first

      if user.currency == "JPY"
        "#{Money.new(amount).format(:ja_default_format)} X #{times} #{I18n.t("common.times")}"
      else
        "#{Money.new(amount).format} X #{times} #{I18n.t("common.times")}"
      end
    end
  end

  def recurring_prices_text
    Array.wrap(recurring_prices).map do |recurring_price|
      # I18n.t("common.#{recurring_price['interval']}_pay")
      # month_pay, year_pay
      if user.currency == "JPY"
        "#{Money.new(recurring_price["amount"]).format(:ja_default_format)} #{I18n.t("common.#{recurring_price['interval']}_pay")}"
      else
        "#{Money.new(recurring_price["amount"]).format} #{I18n.t("common.#{recurring_price['interval']}_pay")}"
      end
    end
  end

  def selling_multiple_times_first_price_text
    if user.currency == "JPY"
      Money.new(selling_multiple_times_price&.first).format(:ja_default_format)
    else
      Money.new(selling_multiple_times_price&.first).format
    end
  end

  def monthly_price_text
    if user.currency == "JPY"
      monthly_price ? "#{I18n.t("common.month_pay")} #{Money.new(monthly_price.amount).format(:ja_default_format)}" : nil
    else
      monthly_price ? "#{I18n.t("common.month_pay")} #{Money.new(monthly_price.amount).format}" : nil
    end
  end

  def year_price_text
    if user.currency == "JPY"
      yearly_price ? "#{I18n.t("common.year_pay")} #{Money.new(yearly_price.amount).format(:ja_default_format)}" : nil
    else
      yearly_price ? "#{I18n.t("common.year_pay")} #{Money.new(yearly_price.amount).format}" : nil
    end
  end

  def serializer(params = {})
    @serializer =
      if is_booking_page?
        SalePages::BookingPageSerializer.new(self, params: params.try(:permit!)&.to_h || {})
      else
        SalePages::OnlineServiceSerializer.new(self, params: params.try(:permit!)&.to_h || {})
      end
  end

  def started?
    selling_start_at.nil? || Time.current > selling_start_at
  end

  def ended?
    selling_end_at && Time.current > selling_end_at
  end

  def sold_out?
    quantity && OnlineServiceCustomerRelation.where(sale_page: self).available.count >= quantity
  end

  def payable?
    free? || user.payable?
  end

  def start_time
    if selling_start_at
      {
        start_type: "start_at",
        start_time_date_part: selling_start_at.to_fs(:date)
      }
    else
      {
        start_type: "now"
      }
    end
  end

  def start_time_text
    if selling_start_at
      I18n.l(selling_start_at, format: :date_with_wday)
    else
      I18n.t("sales.sale_now")
    end
  end

  def end_time
    if selling_end_at
      {
        end_type: "end_at",
        end_time_date_part: selling_end_at.to_fs(:date)
      }
    else
      {
        end_type: "never"
      }
    end
  end

  def end_time_text
    if selling_end_at
      I18n.l(selling_end_at, format: :date_with_wday)
    else
      I18n.t("sales.never_expire")
    end
  end

  def normal_price
    { price_amount: normal_price_amount&.fractional }
  end

  def price
    price_options = {
      price_types: [],
      price_amounts: {}
    }

    if selling_price_amount_cents.present?
      price_options[:price_types] << PAYMENTS[:one_time]
      price_options[:price_amounts].merge!(
        one_time: {
          amount: selling_price_amount.fractional,
          amount_format: selling_price_amount.format
        }
      )
    end

    if selling_multiple_times_price.present?
      price_options[:price_types] << PAYMENTS[:multiple_times]

      price_options[:price_amounts].merge!(
        multiple_times: {
          times: selling_multiple_times_price.size,
          amount: selling_multiple_times_price.first,
          amount_format: Money.new(selling_multiple_times_price.first, user.currency).format
        }
      )
    end

    if recurring_prices.present?
      recurring_prices.each do |recurring_price|
        price_options[:price_types] << recurring_price.interval

        price_options[:price_amounts].merge!(
          recurring_price.interval => {
            amount: recurring_price.amount,
            amount_format: Money.new(recurring_price.amount, user.currency).format
          }
        )
      end
    end

    if selling_price_amount_cents.blank? && selling_multiple_times_price.blank? && recurring_prices.blank?
      price_options[:price_types] << PAYMENTS[:free]
    end

    price_options
  end

  def all_recurring_prices
    Array.wrap(self[:recurring_prices]).map do |recurring_price|
      RecurringPrice.new(recurring_price)
    end
  end

  def recurring_prices
    all_recurring_prices.select { |price| price.active }.sort_by(&:amount)
  end

  def monthly_price
    recurring_prices.find { |price| price.interval == "month" }
  end

  def yearly_price
    recurring_prices.find { |price| price.interval == "year" }
  end

  def normal_price_text
    if user.currency == "JPY"
      normal_price_amount&.format(:ja_default_format) || I18n.t("common.free_price")
    else
      normal_price_amount&.format || I18n.t("common.free_price")
    end
  end

  def quantity_text
    quantity || I18n.t("user_bot.dashboards.sales.online_service_creation.sell_unlimit_number")
  end

  def introduction_video_thumbnail_url
    return @introduction_video_thumbnail_url if defined?(@introduction_video_thumbnail_url)

    @introduction_video_thumbnail_url =
      if introduction_video_url.present?
        VideoThumb::get(introduction_video_url, "medium") || ThumbnailOfVideo.get(introduction_video_url)
      end
  end

  def solution_type
    if is_booking_page?
      "menu"
    else
      product.solution_type
    end
  end
end