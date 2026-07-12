# frozen_string_literal: true

module Admin
  class DashboardsController < AdminController
  def index
    if ENV["COMPAT_API_READ_ENABLED"] == "true"
      @pending_applications = []
      @pending_withdrawals = []
      return
    end

    @pending_applications = BusinessApplication.pending.includes(:user)
    @pending_withdrawals = PaymentWithdrawal.pending.non_zero.includes(:receiver)
  end
  end
end
