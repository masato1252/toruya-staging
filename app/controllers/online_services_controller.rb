# frozen_string_literal: true

class OnlineServicesController < Lines::CustomersController
  layout "booking"

  before_action :online_service

  def show
    @is_service_member = online_service.online_service_customer_relations.available.where(customer: current_customer).exists?
    @is_owner = current_toruy_social_user&.user == current_owner

    if @online_service.course?
      @course_hash = CourseSerializer.new(@online_service).attributes_hash
    else
      @online_service_hash = OnlineServiceSerializer.new(@online_service).attributes_hash.merge(demo: false, light: false)
    end
  end

  private

  def online_service
    @online_service ||= OnlineService.find_by(slug: params[:slug])
  end

  def current_owner
    online_service.user
  end
end
