module Users
  class CreateDefaultSettings < ActiveInteraction::Base
    object :user

    def execute
      if user.profile && user.profile.address.present? && !user.shops.exists?
        shop_name = "#{user.name} #{I18n.t("common.of")}#{I18n.t("common.shop")}"

        shop = Shops::Create.run(
          user: user,
          params: {
            name: shop_name,
            short_name: shop_name,
            zip_code: profile.company_zip_code || profile.zip_code,
            phone_number: profile.company_phone_number.presence || user.phone_number || profile.phone_number,
            email: user.email.presence || profile.email,
            address: profile.company_full_address.presence || profile.personal_full_address,
            website: profile.website
          }
        )
      end

      user.shops.each do |shop|
        unless shop.business_schedules.exists?

          (1..5).each do |day|
            BusinessSchedules::Create.run(
              shop: shop,
              attrs: {
                day_of_week: day,
                business_state: "opened",
                start_time: "09:00",
                end_time: "17:00",
              }
            )
          end

          [6, 0].each do |day|
            BusinessSchedules::Create.run(
              shop: shop,
              attrs: {
                day_of_week: day,
                business_state: "closed",
              }
            )
          end
        end

        if staff && !staff.business_schedules.where(shop: shop).exists?
          BusinessSchedules::Create.run(
            shop: shop,
            staff: staff, attrs: {
              full_time: true
            }
          )
        end
      end

      unless user.reservation_settings.exists?
        user.reservation_settings.create(
          name: I18n.t("common.full_working_time"),
          short_name: I18n.t("common.full_working_time"),
          day_type: ReservationSetting::BUSINESS_DAYS
        )
      end

      if user.shops.exists? && !user.menus.exists?
        menu = user.menus.new
        category = user.categories.find_or_create_by(name: I18n.t("common.category_default_name"))

        outcome = Menus::Update.run(
          menu: menu,
          attrs: {
            name: I18n.t("common.menu_temporary_name"),
            short_name: I18n.t("common.menu_temporary_name"),
            minutes: 60,
            interval: 0,
            min_staffs_number: 1,
            category_ids: [category.id],
            shop_menus_attributes: [
              id: menu.id,
              shop_id: first_shop.id,
              max_seat_number: 1
            ],
            staff_menus_attributes: [
              staff_id: staff.id,
              priority: 0,
              max_customers: 1
            ],
          },
          reservation_setting_id: user.reservation_settings.first.id,
          menu_reservation_setting_rule_attributes: {
            start_date: Date.today
          }
        )
      end

      unless user.contact_groups.exists?
        user.contact_groups.create(name: I18n.t("common.customer_default_group_name"))
      end
    end

    private

    def profile
      @profile ||= user.profile
    end

    def staff
      # user themself
      @staff ||= user.staffs.first
    end

    def first_shop
      @first_shop ||= user.shops.first
    end
  end
end
