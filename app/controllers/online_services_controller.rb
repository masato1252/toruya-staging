# frozen_string_literal: true

class OnlineServicesController < Lines::CustomersController
  layout "booking"

  before_action :online_service, :validate_permission

  def show
    @online_service ||= OnlineService.find_by(slug: params[:slug])
  end

  private

  def online_service
    @online_service ||= OnlineService.find_by(slug: params[:slug])
  end

  def current_owner
    online_service.user
  end

  def validate_permission
    unless online_service.online_service_customer_relations.active.where(customer: current_customer).exists?
      redirect_to sale_page_path(SalePage.find_by!(product: online_service).slug)
    end
  end
end
