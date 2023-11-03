# frozen_string_literal: true

# == Schema Information
#
# Table name: social_rich_menus
#
#  id                  :bigint           not null, primary key
#  bar_label           :string
#  body                :jsonb
#  context             :jsonb
#  current             :boolean
#  default             :boolean
#  end_at              :datetime
#  internal_name       :string
#  social_name         :string
#  start_at            :datetime
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
    social_account || UserBotSocialAccount
  end

  def default_image_url
    social_name ? "https://toruya.s3.ap-southeast-1.amazonaws.com/public/rich_menus/#{social_name}.png" : nil
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

  def actions
    return [] unless body&.dig("areas")

    body_actions = body["areas"].map { |area| area["action"] }
    label_key_mapping = I18n.t("line.bot.keywords").invert
    # ja support only
    # I18n.available_locales
    body_actions.map do |action|
      if ["全ての予約", "新たに予約する", "お問い合わせ", "利用中サービス"].include?(action["text"])
        {
          type: label_key_mapping.dig(action["text"]),
          value: label_key_mapping.dig(action["text"])
        }
      elsif action["label"] == "booking_page"
        {
          type: "booking_page",
          value: action["uri"]
        }
      elsif action["label"] == "sale_page"
        {
          type: "sale_page",
          value: action["uri"]
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
          value: action["uri"],
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
end
