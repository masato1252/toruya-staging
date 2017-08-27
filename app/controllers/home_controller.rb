class HomeController < ApplicationController
  include Authorization
  include ViewHelpers
  layout "home"
  skip_before_action :authenticate_shop_permission!, only: [:index]

  def index
    #XXX Cleanup the shop session to avoid, since we don't need it here and it caused issues that user try to get into unpermission shop.
    session[:shop_id] = nil
    shop_owners = current_user.staff_accounts.map(&:owner).push(current_user).uniq

    # current_user is shop owner and doesn't work for others(staff) and only have one shop
    if (shop_owners.count == 1 && shop_owners.first == current_user) && current_user.shops.count == 1
      redirect_to shop_reservations_path(current_user.shops.first)
    end
  end

  def settings
    super_user = User.find(params[:super_user_id])

    if Ability.new(current_user, super_user).can?(:manage, :all)
      redirect_to settings_user_shops_path(super_user)
    elsif Ability.new(current_user, super_user).can?(:manage, Settings)
      staff = current_user.current_staff(super_user)

      redirect_to settings_user_staffs_path(super_user, shop_id: staff.shop_staffs.first.shop_id)
    else
      staff = current_user.current_staff(super_user)
      redirect_to edit_settings_user_staff_path(super_user, staff, shop_id: staff.shop_staffs.first.shop_id)
    end
  end
end
