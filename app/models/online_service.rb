# frozen_string_literal: true
# == Schema Information
#
# Table name: online_services
#
#  id                    :bigint           not null, primary key
#  company_type          :string           not null
#  content               :json
#  content_url           :string
#  deleted_at            :datetime
#  end_at                :datetime
#  end_on_days           :integer
#  external_purchase_url :string
#  goal_type             :string           not null
#  internal_name         :string
#  name                  :string           not null
#  note                  :text
#  settings              :jsonb            not null
#  slug                  :string
#  solution_type         :string           not null
#  start_at              :datetime
#  tags                  :string           default([]), is an Array
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  company_id            :bigint           not null
#  stripe_product_id     :string
#  upsell_sale_page_id   :integer
#  user_id               :bigint
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
      available_locales: [:ja],
      enabled: true,
      single_content: true,
      stripe_required: false,
      premium_member_required: false,
      solutions: [
        PDF_SOLUTION,
      ]
    },
    {
      key: "ebook",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.ebook.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.ebook.description"),
      available_locales: [:tw],
      enabled: true,
      single_content: true,
      stripe_required: true,
      one_time_charge: true,
      premium_member_required: false,
      solutions: [
        PDF_SOLUTION,
      ]
    },
    {
      key: "free_lesson",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.free_lesson.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.free_lesson.description"),
      available_locales: [:ja],
      enabled: true,
      single_content: true,
      stripe_required: false,
      premium_member_required: false,
      solutions: [
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "paid_lesson",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.paid_lesson.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.paid_lesson.description"),
      available_locales: [:ja],
      enabled: true,
      single_content: true,
      stripe_required: true,
      one_time_charge: true,
      premium_member_required: true,
      solutions: [
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "free_course",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.free_course.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.free_course.description"),
      available_locales: [:ja],
      enabled: true,
      single_content: false,
      stripe_required: false,
      premium_member_required: true,
      solutions: [
        PDF_SOLUTION,
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "course",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.course.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.course.description"),
      available_locales: [:ja, :tw],
      enabled: true,
      single_content: false,
      stripe_required: true,
      one_time_charge: true,
      premium_member_required: true,
      solutions: [
        PDF_SOLUTION,
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "membership",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.membership.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.membership.description"),
      available_locales: [:ja],
      enabled: true,
      single_content: false,
      stripe_required: true,
      recurring_charge: true,
      premium_member_required: true,
      solutions: [
        PDF_SOLUTION,
        VIDEO_SOLUTION,
      ]
    },
    {
      key: "external",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.external.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.external.description"),
      available_locales: [:ja],
      enabled: true,
      single_content: true,
      stripe_required: false,
      one_time_charge: true,
      premium_member_required: false,
      solutions: [
        EXTERNAL_SOLUTION
      ]
    },
    {
      key: "bundler",
      name: I18n.t("user_bot.dashboards.online_service_creation.goals.bundler.title"),
      description: I18n.t("user_bot.dashboards.online_service_creation.goals.bundler.description"),
      available_locales: [:ja],
      enabled: true,
      single_content: false,
      stripe_required: true,
      one_time_charge: true,
      recurring_charge: false,
      premium_member_required: true,
      solutions: [
        PDF_SOLUTION,
        VIDEO_SOLUTION
      ]
    }
  ]

  include DateTimeAccessor
  date_time_accessor :start_at, :end_at, accessor_only: true
  belongs_to :user
  belongs_to :sale_page, foreign_key: :upsell_sale_page_id, required: false
  belongs_to :company, polymorphic: true

  has_many :online_service_customer_relations, -> { current }
  has_many :all_online_service_customer_relations, class_name: "OnlineServiceCustomerRelation"
  has_many :customers, through: :online_service_customer_relations
  has_many :available_online_service_customer_relations, -> { available }, class_name: "OnlineServiceCustomerRelation"
  has_many :handle_required_online_service_customer_relations, -> { current.pending.uncanceled.unexpired }, class_name: "OnlineServiceCustomerRelation"
  has_many :available_customers, through: :available_online_service_customer_relations, source: :customer, class_name: "Customer"
  has_many :chapters, -> { order(position: :asc, id: :asc) }
  has_many :lessons, -> { order("chapters.position": :asc, position: :asc, id: :asc) }, through: :chapters
  has_one :message_template, -> { where(scenario: ::CustomMessages::Customers::Template::ONLINE_SERVICE_MESSAGE_TEMPLATE) }, class_name: "CustomMessage", as: :service
  has_many :episodes
  has_many :bundled_services, foreign_key: :bundler_online_service_id
  has_many :bundled_online_services, through: :bundled_services, source: :online_service
  enum goal_type: GOALS.each_with_object({}) {|goal, h| h[goal[:key]] = goal[:key] }
  # solution_type pdf, video, external, membership, course

  typed_store :settings do |s|
    s.boolean :customer_address_required, default: false, null: false
  end

  scope :not_deleted, -> { where(deleted_at: nil) }
  scope :bundleable, -> { where(goal_type: ['collection', 'free_lesson', 'paid_lesson', 'free_course', 'course', 'membership']) }
  scope :course_like, -> { where(goal_type: ['course', 'free_course']) }

  def self.goals
    goals = GOALS.map do |goal|
      {
        key: goal[:key],
        name: I18n.t("user_bot.dashboards.online_service_creation.goals.#{goal[:key]}.title"),
        description: I18n.t("user_bot.dashboards.online_service_creation.goals.#{goal[:key]}.description"),
        enabled: goal[:enabled],
        single_content: goal[:single_content],
        stripe_required: goal[:stripe_required],
        one_time_charge: goal[:one_time_charge],
        recurring_charge: goal[:recurring_charge],
        premium_member_required: goal[:premium_member_required],
        available_locales: goal[:available_locales],
        solutions: goal[:solutions].map do |solution|
          {
            key: solution[:key],
            name: I18n.t("user_bot.dashboards.online_service_creation.solutions.#{solution[:key]}.title"),
            description: I18n.t("user_bot.dashboards.online_service_creation.solutions.#{solution[:key]}.description"),
            enabled: solution[:enabled]
          }
        end
      }
    end

    goals.select { |goal| goal[:available_locales].include?(Current.business_owner.locale) }
  end

  def internal_product_name
    internal_name.presence || name
  end

  def external_url
    external_purchase_url.presence || content_url
  end

  def solution_options
    self.class.goals.find {|solution| solution[:key] == goal_type}[:solutions]
  end

  def course_like?
    course? || free_course?
  end

  def single_content? # had content_url
    GOALS.find { |goal| goal_type == goal[:key] }[:single_content]
  end

  def charge_required?
    GOALS.find { |goal| goal_type == goal[:key] }[:stripe_required] || external?
  end

  def one_time_charge_required?
    GOALS.find { |goal| goal_type == goal[:key] }[:one_time_charge] && !recurring_charge_required?
  end

  def recurring_charge_required?
    GOALS.find { |goal| goal_type == goal[:key] }[:recurring_charge] || (bundler? && bundled_services.where(subscription: true).exists?)
  end

  def start_at_for_customer(customer)
    start_at || OnlineServiceCustomerRelation.where(online_service: self, customer: customer).first.active_at
  end

  def start_time
    if start_at
      {
        start_type: "start_at",
        start_time_date_part: start_at.to_fs(:date)
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
      I18n.t("common.right_away_after_purchased")
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
        end_time_date_part: end_at.to_fs(:date)
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

  def product_content_url(customer)
    @product_content_url ||=
      if external?
        Utils.url_with_external_browser(content_url) || ""
      elsif bundler?
        ""
      else
        Rails.application.routes.url_helpers.online_service_url(
          slug: slug,
          encrypted_social_service_user_id: MessageEncryptor.encrypt(customer.social_customer.social_user_id)
        )
      end
  end

  def product_content_url_for_text_message(customer)
    @product_content_url_for_text_message ||=
      if external?
        Utils.url_with_external_browser(content_url) || ""
      elsif bundler?
        ""
      else
        Rails.application.routes.url_helpers.online_service_url(slug: slug)
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
      customer_name: customer_or_user.name,
      service_title: name,
      service_start_date: service_start_date,
      service_end_date: service_end_date,
      service_url: product_content_url_for_text_message(customer_or_user)
    }
  end

  def solution_type_for_message
    solution_type
  end

  def default_picture_url
    solution_type_for_message == 'pdf' ? ContentHelper::PDF_THUMBNAIL_URL : ContentHelper::VIDEO_THUMBNAIL_URL
  end

  def picture_url
    if message_template&.picture&.attached?
      # use video_description_card ratio for the resize
      Images::Process.run!(image: message_template.picture, resize: "640x416") || default_picture_url
    elsif course_like? && lessons.exists?
      lessons.first.thumbnail_url || default_picture_url
    elsif bundler?
      ContentHelper::BUNDLER_THUMBNAIL_URL
    else
      thumbnail_url || default_picture_url
    end
  end

  def has_preview?
    !membership? && !bundler?
  end
end
