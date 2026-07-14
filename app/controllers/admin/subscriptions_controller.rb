# frozen_string_literal: true

module Admin
  class SubscriptionsController < AdminController
    def destroy
      if compat_admin_enabled?
        result = compat_v1_delete("/admin/subscription", user_id: params[:user_id])
        render json: result || { status: "failed" }, status: result ? :ok : :bad_gateway
        return
      end

      user = User.find(params[:user_id])
      subscription = user.subscription

      ActiveRecord::Base.transaction do
        user.subscription_charges
          .where(state: :completed)
          .where("expired_date > ?", Subscription.today)
          .update_all(expired_date: Subscription.today)

        subscription.update!(
          plan_id: Subscription::FREE_PLAN_ID,
          recurring_day: nil,
          expired_date: nil,
          next_plan_id: nil,
          rank: 0
        )
      end

      render json: { status: "successful" }
    end

    def update
      if compat_admin_enabled?
        result = compat_v1_put("/admin/subscription", user_id: params[:user_id])
        render json: result || { status: "failed" }, status: result ? :ok : :bad_gateway
        return
      end

      user = User.find(params[:user_id])
      user.subscription.update!(next_plan_id: Subscription::FREE_PLAN_ID)

      render json: { status: "successful" }
    end
  end
end
