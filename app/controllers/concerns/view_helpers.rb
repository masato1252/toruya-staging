# frozen_string_literal: true

module ViewHelpers
  extend ActiveSupport::Concern

  included do
    helper_method :shops
    helper_method :shop
    helper_method :staffs
    helper_method :staff
    helper_method :shop_staff
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
    helper_method :is_owner

    helper_method :super_user
    helper_method :business_owner
    helper_method :current_user
    helper_method :current_users
    helper_method :current_staffs
    helper_method :root_user
    helper_method :social_user
    helper_method :current_social_user
    helper_method :business_owner_id
    helper_method :current_user_of_owner
    helper_method :current_staff_of_owner
  end

  def social_user
    @social_user ||=
      if ENV["DEV_USER_ID"]
        User.find(ENV["DEV_USER_ID"]).social_user
      elsif params[:encrypted_user_id] && (user_id = MessageEncryptor.decrypt(params[:encrypted_user_id]))
        _social_user = User.find_by(id: user_id).social_user
        write_user_bot_cookies(:social_service_user_id, _social_user.social_service_user_id)
        _social_user
      elsif respond_to?(:user_bot_cookies) && user_bot_cookies(:social_service_user_id)
        SocialUser.where.not(user_id: nil).find_by(social_service_user_id: user_bot_cookies(:social_service_user_id)) || SocialUser.find_by(social_service_user_id: user_bot_cookies(:social_service_user_id))
      end
  end
  alias_method :current_social_user, :social_user

  def current_user_of_owner(owner)
    current_users&.find { |u| u.current_staff_account(owner)&.present? }
  end

  def current_staff_of_owner(owner)
    current_user_of_owner(owner).current_staff(owner)
  end

  def current_user
    @current_user ||=
      begin
        user = current_user_of_owner(business_owner)

        if !user && social_user&.user&.super_admin?
          user = business_owner
          Current.admin_debug = true
        end
        write_user_bot_cookies(:current_user_id, user.id) if user

        user
      end
  end

  def current_users
    if Current.admin_debug
      business_owner.social_user.current_users
    else
      social_user&.current_users
    end
  end

  def current_staffs
    social_user&.staffs
  end

  def root_user
    social_user&.root_user
  end

  def super_user
    @super_user ||=
      if params[:encrypted_user_id]
        User.find_by(id: MessageEncryptor.decrypt(params[:encrypted_user_id]))
      elsif params[:business_owner_id]
        User.find_by(id: params[:business_owner_id])
      else
        root_user
      end
  end
  alias_method :business_owner, :super_user

  def business_owner_id
    params[:business_owner_id].presence || business_owner&.id || current_user&.id
  end

  def shops
    @shops ||= if admin?
                 Current.business_owner.shops.order("id")
               else
                 current_user.current_staff.shops.order("id")
               end
  end

  def shop
    @shop ||= Shop.find_by(id: params[:shop_id])
  end

  def staffs
    @staffs = if admin?
                Current.business_owner.staffs.active.order(:id)
              else
                Current.business_owner.staffs.active.joins(:shop_relations).where("shop_staffs.shop_id": shop.id)
              end
  end

  def staff
    @staff ||= Staff.find_by(id: params[:staff_id]) || current_user.current_staff || Current.business_owner.staffs.active.first
  end

  def shop_staff
    @shop_staff ||= ShopStaff.find_by(shop: shop, staff: staff)
  end


  def current_ability
    @current_ability ||= Ability.new(current_user, Current.business_owner, shop)
  end

  def ability(user, at_shop = nil)
    @abilities ||= {}

    cache_key = "user-#{user.id}-shop-#{at_shop&.id}"
    return @abilities[cache_key] if @abilities[cache_key]

    @abilities[cache_key] = Ability.new(current_user, user, at_shop)
  end

  def is_owner
    return @is_owner if defined?(@is_owner)
    @is_owner = (Current.business_owner == current_user)
  end

  def current_user_staff_account
    @current_user_staff_account ||= current_user.current_staff_account
  end

  def current_user_staff
    @current_user_staff ||= current_user.current_staff
  end

  def working_shop_owners(include_user_own: false)
    @working_shop_owners ||= {}

    return @working_shop_owners[include_user_own] if @working_shop_owners[include_user_own]

    staff_account_scope = Current.business_owner.staff_accounts.active

    if include_user_own
      @working_shop_owners[include_user_own] = staff_account_scope.includes(:owner).map(&:owner)
    else
      @working_shop_owners[include_user_own] = staff_account_scope.where.not(owner_id: Current.business_owner.id).includes(:owner).map(&:owner)
    end
  end

  def working_shop_options(shops: )
    shops.map do |shop|
      owner = shop.user
      staff = Current.user.current_staff(owner)
      staff ||= owner.current_staff(owner)

      ::Option.new(
        shop: shop,
        shop_id: shop.id,
        staff: staff,
        staff_id: staff.id,
        owner: owner,
        shop_staff: ShopStaff.where(shop: shop, staff: staff).first
      )
    end.compact
  end

  def owning_shop_options
    @owning_shop_options ||= Current.business_owner.shops.order("id").map do |shop|
      ::Option.new(shop: shop, owner: shop.user)
    end
  end

  def member_shop_ids
    @member_shop_ids ||= begin
      if cookies[:member_shops].nil?
        cookies.clear_across_domains(:member_shops)
        cookies.set_across_domains(:member_shops, manage_shop_options(include_user_own: true).map(&:shop_id).join(","), expires: 20.years.from_now)
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
