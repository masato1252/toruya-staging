# frozen_string_literal: true

class OnlineServicesController < Lines::CustomersController
  layout "booking"

  before_action :online_service

  def show
    @service_member = online_service.online_service_customer_relations.available.where(customer: current_customer).first

    @online_service_hash =
      if @online_service.course?
        CourseSerializer.new(@online_service, { params: { service_member: @service_member }}).attributes_hash
      else
        OnlineServiceSerializer.new(@online_service).attributes_hash.merge(demo: false, light: false)
      end
  end

  def customer_status
    # authorize owner and customer
    @relation = online_service.online_service_customer_relations.where(customer: current_customer).first
    @customer = current_customer
    @is_owner = current_toruy_social_user&.user == current_owner

    render template: "lines/user_bot/services/customers/show", layout: "user_bot"
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
