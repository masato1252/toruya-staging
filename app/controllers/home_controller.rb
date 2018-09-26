class HomeController < ApplicationController
  include Authorization
  include ViewHelpers
  include Sentry
  layout "home"

  def settings
    super_user = User.find(params[:super_user_id])

    if Ability.new(current_user, super_user).can?(:manage, :everything)
      redirect_to settings_user_shops_path(super_user)
    elsif Ability.new(current_user, super_user).can?(:manage, Settings)
      staff = current_user.current_staff(super_user)

      redirect_to settings_user_staffs_path(super_user, shop_id: staff.shop_staffs.first.shop_id)
    elsif staff = current_user.current_staff(super_user)
      redirect_to edit_settings_user_staff_path(super_user, staff, shop_id: staff.shop_staffs.first.shop_id)
    else
      redirect_to member_path, alert: I18n.t("common.no_permission")
    end
  end
end
