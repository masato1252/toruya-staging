class Ability
  include CanCan::Ability

  def initialize(current_user, super_user)
    current_user_staff_account = super_user.owner_staff_accounts.find_by(user_id: current_user.id)
    current_user_level = current_user == super_user
    admin_level = current_user_level || current_user_staff_account.try(:admin?)

    if current_user_level
      can :manage, GoogleContact
    end

    if admin_level
      can :manage, Settings

      if super_user.free_level?
        if !super_user.staffs.active.exists?
          can :create, Staff
        end
      elsif super_user.basic_level? || super_user.premium_level?
        can :swith_staffs_selector, User
        can :create, Staff
      end
    end
  end
end
