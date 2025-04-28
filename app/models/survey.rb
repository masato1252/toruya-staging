# == Schema Information
#
# Table name: surveys
#
#  id          :bigint           not null, primary key
#  active      :boolean          default(TRUE)
#  deleted_at  :datetime
#  description :text
#  owner_type  :string
#  scenario    :string
#  slug        :string
#  title       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  owner_id    :bigint
#  user_id     :bigint           not null
#
# Indexes
#
#  index_surveys_on_owner    (owner_type,owner_id)
#  index_surveys_on_slug     (slug) UNIQUE
#  index_surveys_on_user_id  (user_id)
#
class Survey < ApplicationRecord
  belongs_to :user
  belongs_to :owner, polymorphic: true, optional: true

  has_many :questions, -> { active }, dependent: :destroy, class_name: "SurveyQuestion"
  has_many :responses, dependent: :destroy, class_name: "SurveyResponse"
  has_many :activities, class_name: "SurveyActivity"

  scope :active, -> { where(deleted_at: nil) }

  def message_template_variables(current_user, reservation_customer = nil)
    if reservation_customer
      reservation = reservation_customer.reservation
      customer = reservation_customer.customer
      survey_response = responses.find_by(owner: customer)

      {
        reply_survey_url: Rails.application.routes.url_helpers.reply_survey_url(slug, survey_response.uuid),
        survey_url: Rails.application.routes.url_helpers.survey_url(slug),
        survey_name: title,
        activity_name: reservation.survey_activity&.name || "",
        user_name: current_user.message_name,
        customer_name: customer.message_name,
        activity_slot_time_period: reservation.survey_activity_slot&.slot_time_period || I18n.l(reservation.start_time, format: :date_with_wday),
        shop_name: current_user.shop.display_name,
        shop_phone_number: current_user.shop.phone_number
      }
    else
      {
        reply_survey_url: I18n.t("user_bot.dashboards.surveys.custom_messages.reply_survey_url"),
        survey_url: Rails.application.routes.url_helpers.survey_url(slug),
        survey_name: title,
        activity_name: activities.last&.name || "",
        user_name: current_user.message_name,
        customer_name: current_user.message_name,
        activity_slot_time_period: activities.last&.activity_slots&.last&.slot_time_period || "",
        shop_name: current_user.shop.display_name,
        shop_phone_number: current_user.shop.phone_number
      }
    end
  end
end
