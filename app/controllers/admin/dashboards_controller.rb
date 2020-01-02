module Admin
  class DashboardsController < AdminController
    def index
      @pending_applications = BusinessApplication.pending.includes(:user)
      @pending_withdrawals = PaymentWithdrawal.pending.non_zero.includes(:receiver)
    end
  end
end
