# frozen_string_literal: true

class BusinessesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:show]

  def show
    @presenter = BusinessApplicationPresenter.new(view_context, current_user)
  end

  def apply
    BusinessApplications::Apply.run!(user: current_user)

    redirect_to business_path
  end

  def pay
    outcome = Plans::SubscribeBusinessPlan.run(user: current_user, authorize_token: params[:token])

    if outcome.invalid?
      render json: { message: outcome.errors.full_messages.join(", ") }, status: :unprocessable_entity
      return
    end

    render json: { redirect_path: business_path }
  end
end
