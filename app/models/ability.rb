class Ability
  include CanCan::Ability
  attr_accessor :current_user, :super_user

  def initialize(current_user, super_user)
    @current_user, @super_user = current_user, super_user

    if admin_level
      # manager staff permission
      can :manage, :all
      # can :manage, GoogleContact
      # can :manage, Shop
      # can :create, Staff
      # can :manage, Profile
      # can :edit, Customer
      # can :swith_staffs_selector, User
      # can :edit, "customer_address"

      if super_user.free_level? && super_user.staffs.active.exists?
        cannot :create, Staff
      end

      cannot :read, Shop do |shop|
        shop && !current_user.shops.where(id: shop.id).exists?
      end
    elsif manager_level
      # manager staff permission
      can :read, Shop do |shop|
        current_user_staff.shop_staffs.where(shop: shop).exists?
      end

      can :manage, Settings
      can :edit, Customer
      can :edit, "customer_address"
      can :swith_staffs_selector, User

      # Only handle the staffs under the shops he can manage.
      can :manage_staff_full_time_permission, ShopStaff do |shop_staff|
        shop_staff.staff_id == current_user_staff.id || current_user_staff.shop_staffs.where(shop_id: shop_staff.shop_id).exists?
      end

      can :manage_staff_regular_working_day_permission, ShopStaff do |shop_staff|
        shop_staff.staff_id == current_user_staff.id || current_user_staff.shop_staffs.where(shop_id: shop_staff.shop_id).exists?
      end

      can :manage_staff_temporary_working_day_permission, ShopStaff do |shop_staff|
        shop_staff.staff_id == current_user_staff.id || current_user_staff.shop_staffs.where(shop_id: shop_staff.shop_id).exists?
      end

      can :manage_staff_holiday_permission, ShopStaff do |shop_staff|
        shop_staff.staff_id == current_user_staff.id || current_user_staff.shop_staffs.where(shop_id: shop_staff.shop_id).exists?
      end
    elsif current_user_staff_account.try(:active?) && current_user_staff
      # normal staff permission
      can :read, Shop do |shop|
        current_user_staff.shop_staffs.where(shop: shop).exists?
      end

      can :manage_staff_full_time_permission, ShopStaff do |shop_staff|
        current_user_staff.shop_staffs.where(staff_full_time_permission: true, shop_id: shop_staff.shop_id).exists?
      end

      can :manage_staff_regular_working_day_permission, ShopStaff do |shop_staff|
        current_user_staff.shop_staffs.where(staff_regular_working_day_permission: true, shop_id: shop_staff.shop_id).exists?
      end

      can :manage_staff_temporary_working_day_permission, ShopStaff do |shop_staff|
        current_user_staff.shop_staffs.where(staff_temporary_working_day_permission: true, shop_id: shop_staff.shop_id).exists?
      end

      can :manage_staff_holiday_permission, ShopStaff do |shop_staff|
        current_user_staff.staff_holiday_permission
      end
    end
  end

  private

  def admin_level
    @shop_owner_level ||= current_user == super_user
  end

  def manager_level
    @manager_level ||= current_user_staff_account.try(:manager?) && current_user_staff_account.try(:active?)
  end

  def current_user_staff_account
    current_user.current_staff_account(super_user)
  end

  def current_user_staff
    current_user.current_staff(super_user)
  end
end
