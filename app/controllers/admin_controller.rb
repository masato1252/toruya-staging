# frozen_string_literal: true

class AdminController < ApplicationController
  include Devise::Controllers::Rememberable
  include ControllerHelpers
  before_action :super_admin_required

  def as_user
    user = User.find(params[:as_user_id])
    sign_out
    remember_me(user)
    sign_in(user)

    redirect_to member_path
  end

  private

  def super_admin_required
    unless current_user.super_admin?
      head :not_found
    end
  end
end
