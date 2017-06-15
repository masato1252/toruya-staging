class HomeController < ApplicationController
  layout "home"

  def index
    @shop_owners = current_user.staff_accounts.map(&:owner).push(current_user).uniq

    # current_user is shop owner and doesn't work for others(staff) and only have one shop
    if (@shop_owners.count == 1 && @shop_owners.first == current_user) && current_user.shops.count == 1
      redirect_to shop_reservations_path(current_user.shops.first)
    end
  end

  def settings
    super_user = User.find(params[:super_user_id])

    if Ability.new(current_user, super_user).can?(:manage, Settings)
      redirect_to settings_user_shops_path(super_user)
    else
      redirect_to edit_settings_user_staff_path(super_user, current_user.current_staff(super_user))
    end
  end
end
