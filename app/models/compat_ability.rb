# frozen_string_literal: true

# CanCan rules derived from v1 /auth/session — no ShopStaff / contact_group AR.
class CompatAbility
  include CanCan::Ability

  def initialize(session_data)
    @session = session_data
    staff_level = session_data["staff_level"].to_s
    admin = %w[owner admin].include?(staff_level)
    permissions = Array(session_data["permissions"]).map(&:to_s)

    if admin || permissions.include?("owner") || permissions.include?("admin")
      can :manage, :everything
      can :read, :customers_dashboard
      can :read, :metrics
      can :manage_shop_reservations, Shop
      can :edit, Reservation
      can :edit, Customer
      can :delete, Staff
    else
      can :read, :customers_dashboard
      can :manage_shop_reservations, Shop
      can :edit, Reservation
      can :edit, Customer
    end

    can :read, Customer
  end
end
