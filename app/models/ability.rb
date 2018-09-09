class Ability
  include CanCan::Ability
  attr_accessor :current_user, :super_user

  def initialize(current_user, super_user)
    @current_user, @super_user = current_user, super_user

    if admin_level
      # admin permission
      can :manage, :all
      # can :manage, GoogleContact
      # can :manage, Shop
      # can :create, Staff
      # can :manage, Profile
      # can :edit, Customer
      # can :edit, :customer_contact_info
      # can :swith_staffs_selector, User
      # can :manage, :filter
      # can :manage, :saved_filter
      # can :manage_userself_holiday_permission
      admin_member_ability
    elsif manager_level
      can :manage, :management_stuffs
      # manager staff permission
      can :read, Shop do |shop|
        current_user_staff.shop_staffs.where(shop: shop).exists?
      end

      manager_member_ability

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

      can :manage, "userself_holiday_permission"
    elsif current_user_staff_account.try(:active?) && current_user_staff
      # normal staff permission
      staff_member_ability

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

      can :manage, "userself_holiday_permission" do
        true
      end
    end
  end

  private

  def admin_level
    @shop_owner_level = current_user == super_user
  end

  def manager_level
    @manager_levels ||= {}

    return @manager_levels[super_user.id] unless @manager_levels[super_user.id].nil?

    @manager_levels[super_user.id] = current_user_staff_account.try(:manager?) && current_user_staff_account.try(:active?)
  end

  def current_user_staff_account
    current_user.current_staff_account(super_user)
  end

  def current_user_staff
    current_user.current_staff(super_user)
  end

  def admin_member_ability
    case super_user.member_level
    when "premium"
      # can :create, Staff
      # can :create, Shop
    when "basic", "trial", "free"
      cannot :create, Staff
      shop_permission
    end

    manager_member_ability
    staff_member_ability
  end

  # manager and admin ability
  def manager_member_ability
    can :manage, Settings
    can :edit, Customer
    can :edit, :customer_contact_info
    can :swith_staffs_selector, User

    case super_user.member_level
    when "premium", "trial"
      can :read, :filter
      can :manage, :preset_filter
      can :manage, :saved_filter
    when "basic"
      can :read, :filter
      can :manage, :preset_filter
      cannot :manage, :saved_filter
    when "free"
      cannot :read, :filter
      cannot :manage, :preset_filter
      cannot :manage, :saved_filter
    end

    staff_member_ability
  end

  def staff_member_ability
    can :create, Reservation
    can :create, :daily_reservations
    can :create, :total_reservations
    can :read, :shop_dashboard
    # manage_shop_dashboard only use to check add/edit reservation currently
    can :manage_shop_reservations, Shop do |shop|
      super_user.valid_shop_ids.include?(shop.id)
    end

    case super_user.member_level
    when "premium"
      # can :create, Reservation
      # can :create, :daily_reservations
      # can :create, :total_reservations
      # can :read, :shop_dashboard
    when "trial"
      # can :read, :shop_dashboard
      # can :create, Reservation
      reservation_daily_permission
      reservation_total_permission
    when "free", "basic"
      # can :create, Reservation
      cannot :read, :shop_dashboard
      reservation_daily_permission
      reservation_total_permission
    end
  end

  def shop_permission
    cannot :create, Shop if super_user.shops.exists?
  end

  def reservation_daily_permission
    if Reservations::DailyLimit.run(user: super_user).invalid?
      cannot :create, Reservation
      cannot :create, :daily_reservations
    end
  end

  def reservation_total_permission
    if Reservations::TotalLimit.run(user: super_user).invalid?
      cannot :create, Reservation
      cannot :create, :total_reservations
    end
  end
end
