# == Schema Information
#
# Table name: survey_activity_slots
#
#  id                 :bigint           not null, primary key
#  end_time           :datetime         not null
#  start_time         :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  survey_activity_id :bigint           not null
#
# Indexes
#
#  index_survey_activity_slots_on_survey_activity_id  (survey_activity_id)
#
class SurveyActivitySlot < ApplicationRecord
  belongs_to :survey_activity
  has_one :reservation, dependent: :destroy

  validates :start_time, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time

  def slot_time_period
    return '' if start_time.blank? && end_time.blank?

    start_date = start_time&.strftime('%Y-%m-%d')
    start_day = start_time ? I18n.l(start_time, format: '%a') : ''
    start_time_str = start_time&.strftime('%H:%M')

    end_date = end_time&.strftime('%Y-%m-%d')
    end_day = end_time ? I18n.l(end_time, format: '%a') : ''
    end_time_str = end_time&.strftime('%H:%M')

    start = start_date ? "#{start_date} (#{start_day}) #{start_time_str}" : ''
    end_str = ''

    if end_date
      if start_date == end_date
        end_str = end_time_str
      else
        end_str = "#{end_date} (#{end_day}) #{end_time_str}"
      end
    end

    if start.present? || end_str.present?
      I18n.t('settings.survey.date_range', start: start, end: end_str)
    else
      ''
    end
  end

  private

  def end_time_after_start_time
    return if start_time.blank? || end_time.blank?

    if end_time < start_time
      errors.add(:end_time, :invalid_end_time_before_start_time)
    end
  end
end
