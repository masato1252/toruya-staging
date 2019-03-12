class Ability
  include CanCan::Ability
  attr_accessor :current_user, :super_user, :shop

  def initialize(current_user, super_user, shop = nil)
    @current_user, @super_user, @shop = current_user, super_user, shop

    if admin_level
      # admin permission
      admin_member_ability
    elsif manager_level
      manager_member_ability
      manager_only_ability
    elsif staff_level
      # normal staff permission
      staff_member_ability
      staff_only_ability
    end

    user_ability
  end

  def admin_level
    @shop_owner_level = current_user == super_user
  end
  alias_method :admin?, :admin_level

  def manager_level
    return false unless shop

    @manager_levels ||= {}

    return @manager_levels[shop.id] unless @manager_levels[shop.id].nil?

    @manager_levels[shop.id] = ShopStaff.manager_level.where(staff: current_user_staff, shop: shop).exists?
  end
  alias_method :manager?, :manager_level

  def staff_level
    return false unless shop

    @staff_levels ||= {}

    return @staff_levels[shop.id] unless @staff_levels[shop.id].nil?

    @staff_levels[shop.id] = ShopStaff.staff_level.where(staff: current_user_staff, shop: shop).exists?
  end
  alias_method :staff?, :staff_level

  def responsible_for_reservation(reservation)
    reservation.staff_ids.include?(current_user_staff.id)
  end

  private

  def current_user_staff_account
    current_user.current_staff_account(super_user)
  end

  def current_user_staff
    current_user.current_staff(super_user)
  end

  def admin_member_ability
    can :manage, :everything
    can :manage, GoogleContact
    can :create, Shop
    can :edit, Shop
    can :delete, Shop
    can :create, Staff
    can :delete, Staff
    can :manage, Profile
    can :manage_staff_temporary_working_day_permission, ShopStaff
    can :manage_staff_holiday_permission, ShopStaff

    case super_user.member_level
    when "premium"
    when "basic", "trial", "free"
      cannot :create, Staff
      cannot :create, Shop if super_user.shops.exists?
    end

    manager_member_ability
  end

  # manager ability
  def manager_member_ability
    can :manage, Settings
    can :edit, Customer
    can :edit, :customer_contact_info
    can :swith_staffs_selector, User
    can :manage, :management_stuffs
    can :contact, Customer

    case super_user.member_level
    when "premium", "trial"
      can :read, :filter
      can :manage, :preset_filter
      can :manage, :saved_filter
      can :read, :shop_dashboard
    when "basic"
      can :read, :filter
      can :manage, :preset_filter
      cannot :manage, :saved_filter
      cannot :read, :shop_dashboard
    when "free"
      cannot :read, :filter
      cannot :manage, :preset_filter
      cannot :manage, :saved_filter
      cannot :read, :shop_dashboard
    end

    staff_member_ability
  end

  def staff_member_ability
    can :create_reservation, Shop do |shop|
      shop &&
      super_user.valid_shop_ids.include?(shop.id) &&
      (super_user.premium_member? || admin?) &&
      Reservations::DailyLimit.run(user: super_user).valid? &&
      Reservations::TotalLimit.run(user: super_user).valid? &&
      super_user.reservation_settings.exists? &&
      shop.menus.exists?
    end

    can :create, :reservation_with_settings
    can :create, :daily_reservations
    can :create, :total_reservations
    can :manage, :userself_holiday_permission
    can :edit, Staff do |staff|
      if staff.user_id == super_user.id
        if super_user.premium_member?
          admin_level || manager_level || current_user_staff == staff
        elsif admin_level
          current_user_staff == staff
        end
      end
    end

    can :edit, Reservation do |reservation|
      super_user.valid_shop_ids.include?(reservation.shop_id) && (
        super_user.premium_member? || (
          admin? &&
          (reservation.staff_ids.length == 0 || (reservation.staff_ids.length == 1 && reservation.staff_ids.first == current_user_staff.try(:id)))
        )
      )
    end

    can :see, Reservation do |reservation|
      admin? || manager? || responsible_for_reservation(reservation)
    end

    # manage_shop_dashboard only use to check add/edit reservation currently
    can :manage_shop_reservations, Shop do |shop|
      super_user.valid_shop_ids.include?(shop.id)
    end

    if !super_user.reservation_settings.exists?
      cannot :create, :reservation_with_settings
    end

    can :create_shop_reservations_with_menu, Shop do |shop|
      shop.menus.exists?
    end

    case super_user.member_level
    when "premium"
      can :create, :daily_reservations
      can :create, :total_reservations
    when "trial"
      reservation_daily_permission
      reservation_total_permission
    when "free", "basic"
      reservation_daily_permission
      reservation_total_permission
    end
  end

  def manager_only_ability
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
  end

  def staff_only_ability
    can :manage_staff_full_time_permission, ShopStaff do |shop_staff|
      current_user_staff.shop_staffs.where(staff_full_time_permission: true, shop_id: shop_staff.shop_id).exists?
    end

    can :manage_staff_regular_working_day_permission, ShopStaff do |shop_staff|
      current_user_staff.shop_staffs.where(staff_regular_working_day_permission: true, shop_id: shop_staff.shop_id).exists?
    end

    can :manage_staff_temporary_working_day_permission, ShopStaff do |shop_staff|
      current_user_staff.shop_staffs.where(staff_temporary_working_day_permission: true, shop_id: shop_staff.shop_id).exists?
    end
  end

  # Not under a shop, could not determine user is manager/staff
  def user_ability
    if super_user.premium_member? || admin?
      can :manage_customers, User
      can :read_settings_dashboard, User

      if admin? || current_user_staff.contact_groups.exists?
        can :read, :customers_dashboard
      end
    end
  end

  def reservation_daily_permission
    if Reservations::DailyLimit.run(user: super_user).invalid?
      cannot :create, :daily_reservations
    end
  end

  def reservation_total_permission
    if Reservations::TotalLimit.run(user: super_user).invalid?
      cannot :create, :total_reservations
    end
  end
end
