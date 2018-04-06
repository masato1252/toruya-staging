module ViewHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :shops
    helper_method :shop
    helper_method :staffs
    helper_method :staff
    helper_method :shop_staff
    helper_method :super_user
    helper_method :current_user_staff_account
    helper_method :working_shop_options
    helper_method :working_shop_owners
    helper_method :owning_shop_options
    helper_method :staffs_have_holiday_permission
  end

  def shops
    @shops ||= if can?(:manage, :all)
                 super_user.shops.order("id")
               else
                 current_user.current_staff(super_user).shops.order("id")
               end
  end

  def shop
    @shop ||= Shop.find_by(id: session[:current_shop_id])
  end

  def staffs
    @staffs = if can?(:manage, :all)
                super_user.staffs.active.order(:id)
              else
                super_user.staffs.active.joins(:shop_staffs).where("shop_staffs.shop_id": shop.id)
              end
  end

  def staff
    @staff ||= Staff.find_by(id: params[:staff_id]) || current_user.current_staff(super_user) || super_user.staffs.active.first
  end

  def shop_staff
    @shop_staff ||= ShopStaff.find_by(shop: shop, staff: staff)
  end

  def super_user
    @super_user ||= User.find_by(id: session[:current_super_user_id])
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, super_user)
  end

  def is_owner
    return @is_owner if defined?(@is_owner)
    @is_owner = (super_user == current_user)
  end

  def current_user_staff_account
    @current_user_staff_account ||= current_user.current_staff_account(super_user)
  end

  def working_shop_owners(include_user_own: false)
    @working_shop_owners ||= {}

    return @working_shop_owners[include_user_own] if @working_shop_owners[include_user_own]

    staff_account_scope = current_user.staff_accounts.active

    if include_user_own
      @working_shop_owners[include_user_own] = staff_account_scope.includes(:owner).map(&:owner)
    else
      @working_shop_owners[include_user_own] = staff_account_scope.where.not(owner_id: current_user.id).includes(:owner).map(&:owner)
    end
  end

  def working_shop_options(include_user_own: false)
    @working_shop_options ||= {}

    return @working_shop_options[include_user_own] if @working_shop_options[include_user_own]

    @working_shop_options[include_user_own] = current_user.staff_accounts.active.includes(:staff).map do |staff_account|
      staff = staff_account.staff

      staff.shop_staffs.includes(:shop).map do |shop_staff|
        if include_user_own || shop_staff.shop.user != current_user
          ::Option.new(shop: shop_staff.shop, shop_id: shop_staff.shop_id,
                       staff: staff, staff_id: shop_staff.staff_id,
                       shop_staff: shop_staff)
        end
      end
    end.flatten.compact
  end

  def owning_shop_options
    @owning_shop_options ||= current_user.shops.order("id").map do |shop|
      ::Option.new(shop: shop)
    end
  end

  # the shop options allow "user" to add holidays
  def staffs_have_holiday_permission
    return @staffs_have_holiday_permission if defined?(@staffs_have_holiday_permission)

    @staffs_have_holiday_permission = []
    owners = working_shop_owners(include_user_own: true)

    owners.each do |owner|
      if Ability.new(current_user, owner).can?(:manage, "userself_holiday_permission")
        @staffs_have_holiday_permission << current_user.current_staff(owner)
      end
    end
  end
end
