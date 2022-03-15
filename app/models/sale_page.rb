# frozen_string_literal: true
# == Schema Information
#
# Table name: sale_pages
#
#  id                           :bigint           not null, primary key
#  content                      :json
#  deleted_at                   :datetime
#  flow                         :json
#  internal_name                :string
#  introduction_video_url       :string
#  normal_price_amount_cents    :decimal(, )
#  product_type                 :string           not null
#  quantity                     :integer
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

class SalePage < ApplicationRecord
  PAYMENTS = {
    one_time: "one_time",
    multiple_times: "multiple_times",
    free: "free"
  }.freeze

  belongs_to :product, polymorphic: true # OnlineService/BookingPage
  belongs_to :staff
  belongs_to :sale_template
  belongs_to :user

  has_one_attached :picture # content picture
  has_many_attached :customer_pictures

  scope :active, -> { where(deleted_at: nil) }
  validates :product_type, inclusion: { in: %w[OnlineService BookingPage] }

  monetize :selling_price_amount_cents, allow_nil: true
  monetize :normal_price_amount_cents, allow_nil: true

  def free?
    (selling_price_amount_cents.nil? || selling_price_amount.zero?)  && selling_multiple_times_price.blank? && !external?
  end

  def external?
    !is_booking_page? && product.external?
  end

  def is_booking_page?
    product_type == "BookingPage"
  end

  def product_name
    product&.name
  end

  def selling_prices_text
    [selling_price_text, selling_multiple_times_price_text].compact.join(", ").presence || I18n.t("common.free_price")
  end

  def selling_price_text
    selling_price_amount&.format(:ja_default_format)
  end

  def selling_multiple_times_price_text
    if selling_multiple_times_price.present?
      times = selling_multiple_times_price.size
      amount = selling_multiple_times_price.first

      "#{Money.new(amount).format(:ja_default_format)} X #{times} #{I18n.t("common.times")}"
    end
  end

  def selling_multiple_times_first_price_text
    Money.new(selling_multiple_times_price&.first).format(:ja_default_format)
  end

  def serializer(params = {})
    @serializer ||=
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
        start_time_date_part: selling_start_at.to_s(:date)
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
        end_time_date_part: selling_end_at.to_s(:date)
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
          amount_format: Money.new(selling_multiple_times_price.first).format
        }
      )
    end

    if selling_price_amount_cents.blank? && selling_multiple_times_price.blank?
      price_options[:price_types] << PAYMENTS[:free]
    end

    price_options
  end

  def normal_price_text
    normal_price_amount&.format(:ja_default_format) || I18n.t("common.free_price")
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
