# == Schema Information
#
# Table name: lessons
#
#  id               :bigint           not null, primary key
#  content_url      :string
#  name             :string
#  note             :text
#  position         :integer          default(0)
#  solution_type    :string
#  start_after_days :integer
#  start_at         :datetime
#  chapter_id       :bigint
#
# Indexes
#
#  index_lessons_on_chapter_id  (chapter_id)
#

# start_after_days is how many days the lesson start after customer start using this service
class Lesson < ApplicationRecord
  include ContentHelper

  belongs_to :chapter

  def start_time
    if start_after_days
      {
        start_type: "start_after_days",
        start_after_days: start_after_days
      }
    elsif start_at
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
    if start_after_days
      I18n.t("sales.start_from_after_n_days", days: start_after_days)
    elsif start_at
      I18n.l(start_at, format: :date_with_wday)
    else
      I18n.t("common.right_away_after_purchased")
    end
  end

  def start_time_for_customer(customer)
    if start_at
      start_at
    elsif start_after_days
      chapter.online_service.start_at_for_customer(customer).advance(days: start_after_days).change(hour: 0)
    end
  end

  def started_for_customer?(customer)
    start_time = start_time_for_customer(customer)

    return true unless start_time # start right away service
    return Time.current >= start_time
  end

  def message_template_variables(customer_or_user)
    chapter.online_service.message_template_variables(customer_or_user).merge!(
      {
        customer_name: customer_or_user.name,
        lesson_name: name
      }
    )
  end
end
