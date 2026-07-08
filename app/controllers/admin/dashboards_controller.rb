# frozen_string_literal: true

module Admin
  class DashboardsController < AdminController
  def index
    if compat_read_enabled?
      @pending_applications = []
      @pending_withdrawals = []
      return
    end

    @pending_applications = BusinessApplication.pending.includes(:user)
    @pending_withdrawals = PaymentWithdrawal.pending.non_zero.includes(:receiver)
  end
  end
end
