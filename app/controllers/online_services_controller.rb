# frozen_string_literal: true

class OnlineServicesController < Lines::CustomersController
  layout "booking"

  before_action :online_service

  def show
    @service_member = online_service.online_service_customer_relations.available.where(customer: current_customer).first
    @is_owner = current_toruy_social_user&.user == current_owner

    if @online_service.course?
      @course_hash = CourseSerializer.new(@online_service, { params: { service_member: @service_member, is_owner: @is_owner }}).attributes_hash
    else
      @online_service_hash = OnlineServiceSerializer.new(@online_service).attributes_hash.merge(demo: false, light: false)
    end
  end

  def watch_lesson
    outcome = Lessons::Watch.run(online_service: online_service, customer: current_customer, lesson: Lesson.find(params[:lesson_id]))

    return_json_response(outcome, { watched_lesson_ids: outcome.result.watched_lesson_ids })
  end

  private

  def online_service
    @online_service ||= OnlineService.find_by!(slug: params[:slug])
  end

  def current_owner
    online_service.user
  end
end
