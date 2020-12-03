module BookingPages
  class SmartCreate < ActiveInteraction::Base
    hash :attrs do
      integer :super_user_id
      integer :shop_id
      integer :menu_id, default: nil
      integer :booking_option_id, default: nil
      integer :new_booking_option_price, default: nil
      boolean :new_booking_option_tax_include, default: nil
      string :note, default: nil
    end

    def execute
      ApplicationRecord.transaction do
        unless attrs[:booking_option_id]
          default_booking_option_attrs = {
            name: menu.name,
            display_name: menu.name,
            minutes: menu.minutes,
            amount_cents: attrs[:new_booking_option_price],
            tax_include: attrs[:new_booking_option_tax_include],
            menus: {
              "0" => { 'value' => menu.id, "priority" => 0, "required_time" => menu.minutes },
            }
          }

          new_booking_option = compose(
            BookingOptions::Save,
            booking_option: super_user.booking_options.new,
            attrs: default_booking_option_attrs
          )
        end

        default_booking_page_attrs = {
          name: I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: menu&.short_name || booking_option.name),
          title: I18n.t("user_bot.dashboards.booking_page_creation.default_label", menu_name: menu&.short_name || booking_option.name),
          greeting: I18n.t("user_bot.dashboards.booking_page_creation.default_greeting", menu_name: menu&.short_name || booking_option.name),
          shop_id: shop.id,
          note: attrs[:note],
          options: {
            "0" => { 'value' => attrs[:booking_option_id] || new_booking_option.id },
          },
          draft: false
        }

        compose(
          BookingPages::Save,
          booking_page: super_user.booking_pages.new,
          attrs: default_booking_page_attrs
        )
      end
    end

    private

    def shop
      @shop ||= Shop.find(attrs[:shop_id])
    end

    def menu
      @menu ||= shop.menus.find_by(id: attrs[:menu_id])
    end

    def booking_option
      @booking_option ||= super_user.booking_options.find_by(id: attrs[:booking_option_id])
    end

    def super_user
      @user ||= User.find(attrs[:super_user_id])
    end
  end
end
