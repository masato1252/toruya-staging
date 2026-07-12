# frozen_string_literal: true

module Admin
  class BusinessApplicationsController < AdminController
  def index
    if ENV["COMPAT_API_READ_ENABLED"] == "true"
      @applications = []
      return
    end

    @applications = BusinessApplication.includes(:user)
  end

    def approve
      BusinessApplications::Approve.run!(user: BusinessApplication.find(params[:id]).user)

      redirect_to admin_path
    end

    def reject
      BusinessApplications::Reject.run!(user: BusinessApplication.find(params[:id]).user)

      redirect_to admin_path
    end
  end
end
