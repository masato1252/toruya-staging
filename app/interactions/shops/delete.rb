module Shops
  class Delete < ActiveInteraction::Base
    object :user
    object :shop

    validate :validate_owner

    def execute
      shop.transaction do
        if shop.update(deleted_at: Time.current)
          shop.menus.each do |menu|
            compose(Menus::Delete, menu: menu) if menu.shop_ids.blank?
          end

          unless user.shops.exists?
            user.reservation_settings.destroy_all
            BusinessSchedule.where(staff_id: user.staff_ids).destroy_all
            user.categories.destroy_all
          end

          # The business schedules for that shop
          shop.business_schedules.destroy_all
        else
          errors.add(:shop, :delete_failed)
        end
      end
    end

    private

    def validate_owner
      errors.add(:owner, :invalid) if shop.user != user
    end
  end
end
