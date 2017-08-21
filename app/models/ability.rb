class Ability
  include CanCan::Ability
  attr_accessor :current_user, :super_user

  def initialize(current_user, super_user)
    @current_user, @super_user = current_user, super_user

    if current_user_level
      can :manage, :all
      can :manage, GoogleContact
    end

    if manager_level
      can :manage, :all_shops_selector
      can :read, Shop
      can :manage, Settings
      can :manage, :staff_regular_working_day_permission
      can :update_regular_working_schedule, Shop
      can :manage, :staff_temporary_working_day_permission
      can :update_temoporay_working_schedule, Shop
      can :manage, :staff_holiday_permission

      if super_user.free_level?
        if !super_user.staffs.active.exists?
          can :create, Staff
        end
      elsif super_user.basic_level? || super_user.premium_level?
        can :swith_staffs_selector, User
        can :create, Staff
      end
    end

    # staff schedule permission
    if current_user_staff_account.try(:active?) && current_user_staff
      can :read, Shop do |shop|
        current_user_staff.shop_staffs.where(shop: shop).exists?
      end

      if current_user_staff.shop_staffs.where(staff_regular_working_day_permission: true).exists?
        can :manage, :staff_regular_working_day_permission
        can :update_regular_working_schedule, Shop do |shop|
          current_user_staff.shop_staffs.where(staff_regular_working_day_permission: true, shop: shop).exists?
        end
      end

      if current_user_staff.shop_staffs.where(staff_temporary_working_day_permission: true).exists?
        can :manage, :staff_temporary_working_day_permission
        can :update_temoporay_working_schedule, Shop do |shop|
          current_user_staff.shop_staffs.where(staff_temporary_working_day_permission: true, shop: shop).exists?
        end
      end

      if current_user_staff.staff_holiday_permission
        can :manage, :staff_holiday_permission
      end
    end
  end

  private

  def current_user_level
    @current_user_level ||= current_user == super_user
  end

  def manager_level
    @manager_level ||= current_user_staff_account.try(:manager?)
  end

  def current_user_staff_account
    current_user.current_staff_account(super_user)
  end

  def current_user_staff
    current_user.current_staff(super_user)
  end
end
