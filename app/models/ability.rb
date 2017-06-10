class Ability
  include CanCan::Ability

  def initialize(current_user, super_user)
    current_user_staff_account = super_user.owner_staff_accounts.find_by(user_id: current_user.id)

    if current_user == super_user || current_user_staff_account.try(:admin?)
      can :manage, Settings
    end

    if current_user == super_user
      can :manage, GoogleContact
    end

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
