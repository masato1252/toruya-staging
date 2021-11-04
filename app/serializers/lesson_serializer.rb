# frozen_string_literal: true

class LessonSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :note, :solution_type, :chapter_id, :start_time

  attribute :content_url, if: Proc.new { |lesson, params|
    params[:is_owner] || (params[:service_member].present? && lesson.started_for_customer?(params[:service_member].customer))
  }

  attribute :online_service_id do |lesson|
    lesson.chapter.online_service_id
  end

  attribute :customer_start_time, if: Proc.new { |lesson, params|
    params[:is_owner] || params[:service_member].present?
  } do |lesson, params|
    if params[:service_member].present?
      if !lesson.started_for_customer?(params[:service_member].customer)
        I18n.l(lesson.start_time_for_customer(params[:service_member].customer), format: :date_with_wday)
      end
    end
  end

  attribute :started_for_customer, if: Proc.new { |lesson, params|
    params[:is_owner] || params[:service_member].present?
  } do |lesson, params|
    if params[:service_member].present?
      lesson.started_for_customer?(params[:service_member].customer)
    else
      params[:is_owner]
    end
  end
end
