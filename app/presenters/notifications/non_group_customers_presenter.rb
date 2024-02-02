# frozen_string_literal: true

module Notifications
  class NonGroupCustomersPresenter < ::NotificationsPresenter
    def data
      first_non_group_customer = recent_non_group_customers.first

      first_non_group_customer ? [
        "#{I18n.t("notifications.non_group_customers", number: recent_non_group_customers.count)} #{link_to(I18n.t("notifications.next_non_group_customer"), SiteRouting.new(h).customers_path(first_non_group_customer.user_id, customer_id: first_non_group_customer.id))}"
      ] : []
    end

    private

    def recent_non_group_customers
      @recent_non_group_customers ||= Customer.where(user: owners_who_current_user_have_ability_to_manage_customers, contact_group_id: nil).active
    end

    def owners_who_current_user_have_ability_to_manage_customers
      @owners_who_current_user_have_ability_to_manage_customers ||= working_shop_owners.select { |owner| h.ability(owner).can?(:edit, Customer) }
    end
  end
end
