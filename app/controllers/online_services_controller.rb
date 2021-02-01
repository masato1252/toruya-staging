class OnlineServicesController < ActionController::Base
  layout "booking"

  def show
    @online_service ||= OnlineService.find_by(slug: params[:slug])
  end
end
