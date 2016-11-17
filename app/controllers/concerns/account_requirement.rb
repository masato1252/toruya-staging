module AccountRequirement
  extend ActiveSupport::Concern

  # Bottom Checking First
  included do
    before_action :require_menu
    before_action :require_shop
    before_action :require_contacts
    before_action :require_user_name
  end

  def require_user_name
    if !current_user.name
      flash.now[:alert] = "Please go to #{view_context.link_to("Account page", settings_profile_path)} to fill your information".html_safe
    end
  end

  def require_contacts
    if !current_user.uid
      flash.now[:alert] = "Please go to #{view_context.link_to("Contacts page", settings_contact_groups_path)} to connect your google account".html_safe
    end
  end

  def require_shop
    if !current_user.shops.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Shop page", settings_shops_path)} to create your shops".html_safe
    end
  end

  def require_menu
    if !current_user.menus.exists?
      flash.now[:alert] = "Please go to #{view_context.link_to("Menu page", settings_menus_path)} to create your Menu".html_safe
    end
  end
end
