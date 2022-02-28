# frozen_string_literal: true
# == Schema Information
#
# Table name: online_services
#
#  id                  :bigint           not null, primary key
#  company_type        :string           not null
#  content             :json
#  content_url         :string
#  end_at              :datetime
#  end_on_days         :integer
#  goal_type           :string           not null
#  name                :string           not null
#  slug                :string
#  solution_type       :string           not null
#  start_at            :datetime
#  tags                :string           default([]), is an Array
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  stripe_product_id   :string
#  upsell_sale_page_id :integer
#  user_id             :bigint
#
# Indexes
#
#  index_online_services_on_slug     (slug)
#  index_online_services_on_user_id  (user_id)
#

class OnlineService < ApplicationRecord
  include ContentHelper

  VIDEO_SOLUTION = {
    key: "video",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.video.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.video.description"),
    enabled: true,
  }

  PDF_SOLUTION = {
    key: "pdf",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.pdf.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.pdf.description"),
    enabled: true,
  }

  EXTERNAL_SOLUTION = {
    key: "external",
    name: I18n.t("user_bot.dashboards.online_service_creation.solutions.external.title"),
    description: I18n.t("user_bot.dashboards.online_service_creation.solutions.external.description"),
    enabled: true,
  }

  SOLUTIONS = [
    VIDEO_SOLUTION,
    PDF_SOLUTION,
    EXTERNAL_SOLUTION
  ]

  GOALS = [
    {
      key: "collection",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.collection.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.collection.description"),
      enabled: true,
      stripe_required: false,
      premium_member_required: false,
      skip_solution_step_on_creation: false,
      skip_line_message_step_on_creation: true,
      solutions: [
        PDF_SOLUTION,
      ]
    },
    {
      key: "free_lesson",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.free_lesson.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.free_lesson.description"),
      enabled: true,
      stripe_required: false,
      premium_member_required: false,
      skip_solution_step_on_creation: false,
      skip_line_message_step_on_creation: true,
      solutions: [
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "paid_lesson",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.paid_lesson.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.paid_lesson.description"),
      enabled: true,
      stripe_required: true,
      premium_member_required: false,
      skip_solution_step_on_creation: false,
      skip_line_message_step_on_creation: true,
      solutions: [
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "course",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.course.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.course.description"),
      enabled: true,
      stripe_required: true,
      premium_member_required: true,
      skip_solution_step_on_creation: true,
      skip_line_message_step_on_creation: true,
      solutions: [
        PDF_SOLUTION,
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "membership",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.membership.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.membership.description"),
      enabled: true,
      stripe_required: true,
      recurring_charge: true,
      premium_member_required: true,
      skip_solution_step_on_creation: true,
      skip_end_time_step_on_creation: true,
      skip_line_message_step_on_creation: false,
      solutions: [
        PDF_SOLUTION,
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "external",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.external.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.external.description"),
      enabled: true,
      stripe_required: false,
      premium_member_required: false,
      skip_solution_step_on_creation: false,
      skip_line_message_step_on_creation: true,
      solutions: [
        EXTERNAL_SOLUTION
      ]
    }
  ]

  include DateTimeAccessor
  date_time_accessor :start_at, :end_at, accessor_only: true
  belongs_to :user
  belongs_to :sale_page, foreign_key: :upsell_sale_page_id, required: false
  belongs_to :company, polymorphic: true

  has_many :online_service_customer_relations, -> { current }
  has_many :customers, through: :online_service_customer_relations
  has_many :available_online_service_customer_relations, -> { available }, class_name: "OnlineServiceCustomerRelation"
  has_many :available_customers, through: :available_online_service_customer_relations, source: :customer, class_name: "Customer"
  has_many :chapters
  has_many :lessons, -> { order(chapter_id: :asc, id: :asc) }, through: :chapters
  has_one :message_template, -> { where(scenario: CustomMessage::ONLINE_SERVICE_MESSAGE_TEMPLATE) }, class_name: "CustomMessage", as: :service
  has_many :episodes

  enum goal_type: GOALS.each_with_object({}) {|goal, h| h[goal[:key]] = goal[:key] }

  def solution_options
    GOALS.find {|solution| solution[:key] == goal_type}[:solutions]
  end

  def charge_required?
    GOALS.find { |goal| goal_type == goal[:key] }[:stripe_required] || goal_type == 'external'
  end

  def recurring_charge_required?
    GOALS.find { |goal| goal_type == goal[:key] }[:recurring_charge]
  end

  def start_at_for_customer(customer)
    start_at || self.online_service_customer_relations.find_by!(customer: customer).active_at
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

  def message_template_variables(customer_or_user)
    service_start_date, service_end_date =
      case customer_or_user
      when Customer
        relation = self.online_service_customer_relations.find_by!(online_service: self, customer: customer_or_user)

        [
          relation.start_date_text,
          relation.end_date_text
        ]
      when User
        # XXX: only used for demo
        [
          I18n.l(start_at || Time.current, format: :long_date),
          current_expire_time ? I18n.l(current_expire_time, format: :long_date) : I18n.t("sales.never_expire")
        ]
      end

    {
      customer_name: customer_or_user.display_last_name,
      service_title: name,
      service_start_date: service_start_date,
      service_end_date: service_end_date
    }
  end

  def solution_type_for_message
    if course? && lessons.exists?
      lessons.first.solution_type
    else
      solution_type
    end
  end

  def picture_url
    if course? && lessons.exists?
      lessons.first.thumbnail_url || sale_page.introduction_video_url
    elsif membership? && message_template.picture.attached?
      # use content8 ratio for the resize
      Rails.application.routes.url_helpers.url_for(message_template.picture.variant(combine_options: { resize: "640x416", flatten: true }))
    else
      thumbnail_url || sale_page.introduction_video_url
    end
  end
end
