# frozen_string_literal: true
# == Schema Information
#
# Table name: online_services
#
#  id                  :bigint(8)        not null, primary key
#  user_id             :bigint(8)
#  name                :string           not null
#  goal_type           :string           not null
#  solution_type       :string           not null
#  end_at              :datetime
#  end_on_days         :integer
#  upsell_sale_page_id :integer
#  content             :json
#  company_type        :string           not null
#  company_id          :bigint(8)        not null
#  slug                :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  start_at            :datetime
#
# Indexes
#
#  index_online_services_on_slug     (slug)
#  index_online_services_on_user_id  (user_id)
#

require "thumbnail_of_video"

class OnlineService < ApplicationRecord
  include DateTimeAccessor
  date_time_accessor :start_at, :end_at, accessor_only: true
  belongs_to :user
  belongs_to :sale_page, foreign_key: :upsell_sale_page_id, required: false
  belongs_to :company, polymorphic: true

  has_many :online_service_customer_relations

  def start_time
    if start_at
      {
        start_type: "start_at",
        start_time_date_part: start_at.to_s(:date)
      }
    else
      {
        start_type: "now"
      }
    end
  end

  def start_time_text
    if start_at
      I18n.l(start_at, format: :date_with_wday)
    else
      I18n.t("sales.sale_now")
    end
  end

  def end_time
    if end_on_days
      {
        end_type: "end_on_days",
        end_on_days: end_on_days
      }
    elsif end_at
      {
        end_type: "end_at",
        end_time_date_part: end_at.to_s(:date)
      }
    else
      {
        end_type: "never"
      }
    end
  end

  def end_time_text
    if end_on_days
      I18n.t("sales.expire_after_n_days", days: end_on_days)
    elsif end_at
      I18n.l(end_at, format: :date_with_wday)
    else
      I18n.t("sales.never_expire")
    end
  end

  def current_expire_time
    if end_at
      end_at
    elsif end_on_days
      Time.current.advance(days: end_on_days)
    end
  end

  def thumbnail_url
    @thumbnail_url ||=
      case solution_type
      when "video"
        VideoThumb::get(content["url"], "medium") || ThumbnailOfVideo.get(content["url"]) if content&["url"]
      else
      end
  end
end
