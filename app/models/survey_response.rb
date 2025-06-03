# == Schema Information
#
# Table name: survey_responses
#
#  id                 :bigint           not null, primary key
#  owner_type         :string
#  state              :integer          default("pending")
#  uuid               :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  owner_id           :bigint
#  survey_activity_id :integer
#  survey_id          :bigint           not null
#
# Indexes
#
#  idx_survey_responses_on_activity_and_owner  (survey_activity_id,owner_type,owner_id) UNIQUE
#  index_survey_responses_on_owner             (owner_type,owner_id)
#  index_survey_responses_on_survey_id         (survey_id)
#  index_survey_responses_on_uuid              (uuid) UNIQUE
#
class SurveyResponse < ApplicationRecord
  ACTIVE_STATES = %w[pending accepted].freeze

  belongs_to :survey
  belongs_to :owner, polymorphic: true
  belongs_to :survey_activity, optional: true
  has_many :question_answers, dependent: :destroy
  scope :active, -> { where(state: ACTIVE_STATES) }

  validates :owner, presence: true

  enum state: {
    pending: 0,
    accepted: 1,
    canceled: 2
  }

  def is_activity?
    survey_activity_id.present?
  end

  def message_template_variables(customer)
    {
      reply_survey_url: Rails.application.routes.url_helpers.reply_survey_url(survey.slug, uuid),
      survey_url: Rails.application.routes.url_helpers.survey_url(survey.slug),
      survey_name: survey.title,
      activity_name: survey_activity&.name || "",
      user_name: survey.user.message_name,
      customer_name: customer.message_name
    }
  end

  def survey_response_url
    if is_activity?
      Rails.application.routes.url_helpers.lines_user_bot_survey_activity_survey_response_url(survey, survey_activity, self, business_owner_id: survey.user.id, encrypted_user_id: MessageEncryptor.encrypt(survey.user.id, expires_at: 1.week.from_now))
    else
      Rails.application.routes.url_helpers.lines_user_bot_survey_response_url(survey, self, business_owner_id: survey.user.id, encrypted_user_id: MessageEncryptor.encrypt(survey.user.id, expires_at: 1.week.from_now))
    end
  end

  def activity_answers
    question_answers.select { |qa| qa.survey_activity.present? }
  end

  def non_activity_answers
    question_answers.reject { |qa| qa.survey_activity.present? }
  end

  def customer
    if owner.is_a?(Customer)
      owner
    elsif owner.is_a?(ReservationCustomer)
      owner.customer
    else
      raise "Unknown owner type: #{owner.class}"
    end
  end

  def reservation_customers
    if is_activity?
      ReservationCustomer.where(survey_activity: survey_activity, customer: customer)
    else
      []
    end
  end

  def answer_sentences
    grouped_answers = non_activity_answers.group_by(&:survey_question_id)
    grouped_answers.map do |_, answers|
      if answers.first.text_answer.present?
        answers.first.text_answer
      elsif answers.length > 1
        answers.map(&:survey_option_snapshot).join(', ')
      else
        answers.first.survey_option_snapshot
      end
    end
  end
end
