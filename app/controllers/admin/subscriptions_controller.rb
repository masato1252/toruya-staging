# frozen_string_literal: true

module Admin
  class SubscriptionsController < AdminController
    def destroy
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
      user = User.find(params[:user_id])
      user.subscription.update!(next_plan_id: Subscription::FREE_PLAN_ID)

      render json: { status: "successful" }
    end
  end
end
