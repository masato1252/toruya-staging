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
  PDF_LOGO_URL = "https://toruya.s3-ap-southeast-1.amazonaws.com/public/pdf_logo.png"

  VIDEO_SOLUTION = {
    key: "video",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.video.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.video.description"),
    enabled: true
  }

  AUDIO_SOLUTION = {
    key: "audio",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.audio.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.audio.description"),
    enabled: false
  }

  PDF_SOLUTION = {
    key: "pdf",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.pdf.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.pdf.description"),
    enabled: true
  }

  QUESTIONNAIRE_SOLUTION = {
    key: "questionnaire",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.questionnaire.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.questionnaire.description"),
    enabled: false
  }

  DIAGNOSIS_SOLUTION = {
    key: "diagnosis",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.diagnosis.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.diagnosis.description"),
    enabled: false
  }

  GOALS = [
    {
      key: "collection",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.collection.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.collection.description"),
      enabled: true,
      stripe_required: false,
      solutions: [
        VIDEO_SOLUTION,
        AUDIO_SOLUTION,
        PDF_SOLUTION,
        QUESTIONNAIRE_SOLUTION,
        DIAGNOSIS_SOLUTION
      ]
    },
    {
      key: "customers",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.customers.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.customers.description"),
      enabled: true,
      stripe_required: true,
      solutions: [
        VIDEO_SOLUTION,
        AUDIO_SOLUTION
      ]
    },
    {
      key: "price",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.price.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.price.description"),
      enabled: true,
      stripe_required: true,
      solutions: [
        VIDEO_SOLUTION,
        AUDIO_SOLUTION
      ]
    },
    {
      key: "upsell",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.upsell.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.upsell.description"),
      enabled: false,
      stripe_required: true,
      solutions: [
        VIDEO_SOLUTION
      ]
    }
  ]

  include DateTimeAccessor
  date_time_accessor :start_at, :end_at, accessor_only: true
  belongs_to :user
  belongs_to :sale_page, foreign_key: :upsell_sale_page_id, required: false
  belongs_to :company, polymorphic: true

  has_many :online_service_customer_relations

  def charge_required?
    GOALS.find { |goal| goal_type == goal[:key] }[:stripe_required]
  end

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
        VideoThumb::get(content["url"], "medium") || ThumbnailOfVideo.get(content["url"]) if content && content["url"]
      when "pdf"
        PDF_LOGO_URL
      else
      end
  end
end
