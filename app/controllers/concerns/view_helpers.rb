# frozen_string_literal: true

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
    helper_method :current_user_staff
    helper_method :working_shop_options
    helper_method :working_shop_owners
    helper_method :owning_shop_options
    helper_method :manage_shop_options
    helper_method :member_shops_options
    helper_method :member_shop_ids
    helper_method :staffs_have_holiday_permission
    helper_method :ability
    helper_method :admin?
    helper_method :manager?
    helper_method :in_personal_dashboard?
    helper_method :shop_dashboard_id
    helper_method :basic_settings_presenter
    helper_method :booking_settings_presenter
    helper_method :previous_controller_is
    helper_method :working_time_range
  end

  def shops
    @shops ||= if admin?
                 super_user.shops.order("id")
               else
                 current_user.current_staff(super_user).shops.order("id")
               end
  end

  def shop
    @shop ||= Shop.find_by(id: from_line_bot ? user_bot_cookies(:current_shop_id) : session[:current_shop_id])
  end

  def staffs
    @staffs = if admin?
                super_user.staffs.active.order(:id)
              else
                super_user.staffs.active.joins(:shop_relations).where("shop_staffs.shop_id": shop.id)
              end
  end

  def staff
    @staff ||= Staff.find_by(id: params[:staff_id]) || current_user.current_staff(super_user) || super_user.staffs.active.first
  end

  def shop_staff
    @shop_staff ||= ShopStaff.find_by(shop: shop, staff: staff)
  end

  def super_user
    @super_user ||= User.find_by(id: from_line_bot ? user_bot_cookies(:current_super_user_id) : session[:current_super_user_id])
  end

  def current_ability
    @current_ability ||= Ability.new(current_user, super_user, shop)
  end

  def ability(user, at_shop = nil)
    @abilities ||= {}

    cache_key = "user-#{user.id}-shop-#{at_shop&.id}"
    return @abilities[cache_key] if @abilities[cache_key]

    @abilities[cache_key] = Ability.new(current_user, user, at_shop)
  end

  def is_owner
    return @is_owner if defined?(@is_owner)
    @is_owner = (super_user == current_user)
  end

  def current_user_staff_account
    @current_user_staff_account ||= current_user.current_staff_account(super_user)
  end

  def current_user_staff
    @current_user_staff ||= current_user.current_staff(super_user)
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

  def working_shop_options(include_user_own: false, manager_above_level_required: false)
    @working_shop_options ||= {}
    cache_key = "user-own-#{include_user_own}-manager-level-#{manager_above_level_required}"

    return @working_shop_options[cache_key] if @working_shop_options[cache_key]

    @working_shop_options[cache_key] = current_user.staff_accounts.active.includes(:staff).map do |staff_account|
      staff = staff_account.staff

      staff.shop_relations.includes(shop: :user).map do |shop_relation|
        shop = shop_relation.shop

        if include_user_own || shop.user != current_user
          next if manager_above_level_required && ability(shop.user, shop).cannot?(:manage, :management_stuffs)

          ::Option.new(shop: shop, shop_id: shop.id,
                       staff: staff, staff_id: shop_relation.staff_id,
                       owner: shop.user,
                       shop_staff: shop_relation)
        end
      end
    end.flatten.compact.sort_by { |option| option.shop_id }
  end

  def manage_shop_options(include_user_own: false)
    working_shop_options(include_user_own: include_user_own, manager_above_level_required: true)
  end

  def owning_shop_options
    @owning_shop_options ||= current_user.shops.order("id").map do |shop|
      ::Option.new(shop: shop, owner: shop.user)
    end
  end

  def member_shop_ids
    @member_shop_ids ||= begin
      if cookies[:member_shops].nil?
        cookies[:member_shops] = manage_shop_options(include_user_own: true).map(&:shop_id).join(",")
      end

      @member_shop_ids ||= cookies[:member_shops].split(",") & manage_shop_options(include_user_own: true).map { |o| o.shop_id.to_s }
    end
  end

  def member_shops_options
    @member_shops_options ||= working_shop_options(include_user_own: true).find_all { |s| member_shop_ids.include?(s.shop_id.to_s) }
  end

  def basic_settings_presenter
    @basic_settings_presenter ||= Tours::BasicSettingsPresenter.new(view_context, current_user)
  end

  def booking_settings_presenter
    @booking_settings_presenter ||= Tours::BookingSettingsPresenter.new(view_context, current_user)
  end

  def admin?
    can?(:manage, :everything)
  end

  # manage or admin
  def manager?
    can?(:manage, :management_stuffs)
  end

  def previous_controller_is(controller_name)
    Rails.application.routes.recognize_path(request.referrer || "")[:controller] == controller_name
  end

  def in_personal_dashboard?
    cookies[:dashboard_mode] == "user"
  end

  def shop_dashboard_id
    cookies[:dashboard_mode]
  end

  def working_time_range
    return @working_time_range if defined?(@working_time_range)

    date = params[:reservation_date] ? Time.zone.parse(params[:reservation_date]).to_date : Time.zone.now.to_date

    time_range_outcome = Reservable::Time.run(shop: shop, date: date)
    @working_time_range = time_range_outcome.valid? ? time_range_outcome.result : nil
  end
end
