class Users::PasswordsController < Devise::PasswordsController
  protected

  # def after_resetting_password_path_for(resource)
  #   if session[:super_user_id_from_staff_account]
  #     super_user = User.find(session[:super_user_id_from_staff_account])
  #     ability = Ability.new(resource, super_user)
  #
  #     if ability.can?(:manage, :staff_regular_working_day_permission) || ability.can?(:manage, :staff_temporary_working_day_permission)
  #       working_schedules_settings_user_working_time_staff_path(super_user, resource.current_staff(super_user))
  #     elsif ability.can?(:manage, :staff_holiday_permission)
  #       holiday_schedules_settings_user_working_time_staff_path(super_user, current_user.current_staff(super_user))
  #     else
  #       edit_settings_user_staff_path(super_user, current_user.current_staff(super_user))
  #     end
  #   else
  #     super(resource)
  #   end
  # end
end
