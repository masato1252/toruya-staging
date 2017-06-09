class Ability
  include CanCan::Ability

  def initialize(user)
    # user ||= User.new # guest user (not logged in)
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities

    if user.free_level?
      if !user.staffs.exists?
        can :create, Staff
      end
    elsif user.basic_level? || user.premium_level?
      can :swith_staffs_selector, User
      can :create, Staff
    end
  end
end
