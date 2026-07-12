# frozen_string_literal: true

module Admin
  class BusinessApplicationsController < AdminController
  def index
    if compat_read_data_plane?
      @applications = []
      return
    end

    @applications = BusinessApplication.includes(:user)
  end

    def approve
      return compat_transition(:approve) if ENV["COMPAT_API_READ_ENABLED"] == "true"

      BusinessApplications::Approve.run!(user: BusinessApplication.find(params[:id]).user)

      redirect_to admin_path
    end

    def reject
      return compat_transition(:reject) if ENV["COMPAT_API_READ_ENABLED"] == "true"

      BusinessApplications::Reject.run!(user: BusinessApplication.find(params[:id]).user)

      redirect_to admin_path
    end

    private

    def compat_transition(action)
      response = compat_v1_post_response("/admin/business_applications/#{params[:id]}/#{action}")
      unless response&.dig(:success)
        redirect_to admin_path, alert: "申請の更新に失敗しました"
        return
      end

      # v1 reports whether it changed a pending record. Queue the existing
      # Rails mail only after that confirmed transition, so retries do not
      # produce duplicate approval/rejection emails.
      queue_transition_mail(action) if response[:body]["transitioned"] == true
      redirect_to response[:body]["redirect_to"].presence || admin_path
    end

    def queue_transition_mail(action)
      application = BusinessApplication.find_by(id: params[:id])
      unless application
        Rails.logger.warn("[Admin::BusinessApplications] transitioned application #{params[:id]} is unavailable for mail")
        return
      end

      BusinessApplicationMailer
        .with(business_application: application)
        .public_send("applicant_#{action}")
        .deliver_later
    rescue StandardError => e
      # The transition has already succeeded remotely. Do not turn a mail
      # enqueue failure into a failed admin mutation or retry the email blindly.
      Rails.logger.warn("[Admin::BusinessApplications] mail enqueue failed for #{params[:id]}: #{e.message}")
    end
  end
end
