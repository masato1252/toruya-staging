# frozen_string_literal: true

# == Schema Information
#
# Table name: social_rich_menus
#
#  id                  :bigint           not null, primary key
#  bar_label           :string
#  body                :jsonb
#  current             :boolean
#  default             :boolean
#  end_at              :datetime
#  internal_name       :string
#  locale              :string           default("ja"), not null
#  social_name         :string
#  start_at            :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  social_account_id   :integer
#  social_rich_menu_id :string
#
# Indexes
#
#  current_rich_menu                                             (social_account_id,current) UNIQUE
#  default_rich_menu                                             (social_account_id,default) UNIQUE
#  index_social_rich_menus_on_social_account_id_and_social_name  (social_account_id,social_name)
#

require "user_bot_social_account"
require "tw_user_bot_social_account"

class SocialRichMenu < ApplicationRecord
  LINE_OFFICIAL_RICH_MENU_KEY = "line_official"
  KEYWORDS = I18n.t("line.bot.keywords").keys.map(&:to_s) # "incoming_reservations", "booking_pages", "contacts", "services"
  store_accessor :context, %i[image_errors]

  belongs_to :social_account, required: false
  scope :current, -> { where(current: true) }
  scope :not_official, -> { where.not(social_name: LINE_OFFICIAL_RICH_MENU_KEY) }
  scope :pending, -> { where(current: nil) }
  scope :default, -> { where(default: true) }

  has_one_attached :image # content picture

  def account
    social_account || (locale == 'tw' ? TwUserBotSocialAccount : UserBotSocialAccount)
  end

  def default_image_url
    return nil unless social_name

    if locale == "tw"
      "https://www.toruya.tw/app_assets/customer_reservations.png"
    else
      "https://toruya.s3.ap-southeast-1.amazonaws.com/public/rich_menus/#{social_name}.png"
    end
  end

  def state
    if current || (end_at && end_at > Time.current)
      "active"
    else
      "pending"
    end
  end

  def official?
    social_name == LINE_OFFICIAL_RICH_MENU_KEY
  end

  def layout_type
    return "a" unless body&.dig("areas")

    body_bounds = body["areas"].map { |area| area["bounds"] }

    RichMenus::Body::LAYOUT_TYPES.find do |k, h|
      h[:action_bounds].as_json == body_bounds
    end.first
  end

  def action_values
    actions.map { |action| action[:value] }
  end

  def self.line_keywords
    I18n.available_locales.map { |locale| I18n.t("line.bot.keywords", locale: locale).values }.flatten.uniq
  end

  def self.label_key_mapping
    I18n.available_locales.map { |locale| 
      I18n.t("line.bot.keywords", locale: locale).invert
    }.reduce({}, :merge)
  end

  def actions
    return [] unless body&.dig("areas")

    body_actions = body["areas"].map { |area| area["action"] }
    # ja support only
    # I18n.available_locales
    body_actions.map do |action|
      if self.class.line_keywords.include?(action["text"])
        {
          type: self.class.label_key_mapping.dig(action["text"]),
          value: self.class.label_key_mapping.dig(action["text"])
        }
      elsif action["label"] == "booking_page"
        {
          type: "booking_page",
          value: rollback_to_content_url(action["uri"])
        }
      elsif action["label"] == "sale_page"
        {
          type: "sale_page",
          value: rollback_to_content_url(action["uri"])
        }
      elsif action["type"] == "message"
        {
          type: "text",
          value: action["text"],
          desc: action["label"]
        }
      elsif action["type"] == "uri"
        {
          type: "uri",
          value: rollback_to_content_url(action["uri"]),
          desc: action["label"]
        }
      end
    end
  end

  def image_url
    if image.attached?
      image.url
    else
      File.join(Rails.root, "app", "assets", "images", "rich_menus", "#{social_name}.png")
    end
  end

  def rollback_to_content_url(url)
    url.include?(Rails.application.routes.url_helpers.function_redirect_url) ? CGI.parse(URI.parse(url).query)["content"].first : url
  end
end
