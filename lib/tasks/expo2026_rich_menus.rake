# frozen_string_literal: true

namespace :expo2026 do
  namespace :rich_menus do
    desc "Create Expo 2026 campaign rich menus and link target LINE users"
    task apply: :environment do
      $stdout.sync = true
      abort "This task supports only the Japanese Toruya official LINE account." unless I18n.available_locales.include?(:ja)

      image_dir = Pathname.new(ENV.fetch("IMAGE_DIR", Rails.root.join("tmp").to_s))
      dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch("DRY_RUN", "false"))
      default_key = UserBotLines::RichMenus::Expo2026Campaign::NOLOGIN_KEYS.first

      puts "[Expo2026] image_dir=#{image_dir}"
      puts "[Expo2026] dry_run=#{dry_run}"

      unless dry_run
        create_campaign_menus!(image_dir: image_dir, default_key: default_key)
      end

      nologin_scope = SocialUser
        .where(user_id: nil, locale: UserBotLines::RichMenus::Expo2026Campaign::LOCALE)
        .where.not(
          social_service_user_id: SocialUser.where.not(user_id: nil).select(:social_service_user_id)
        )

      event_line_users = EventLineUser.joins(:event_participants).distinct.to_a.reject(&:toruya_registered?)

      puts "[Expo2026] nologin social_users=#{nologin_scope.count}"
      puts "[Expo2026] only-event line_users=#{event_line_users.size}"

      unless dry_run
        link_nologin_users!(nologin_scope)
        link_only_event_users!(event_line_users)
      end

      puts "[Expo2026] done"
    end

    def create_campaign_menus!(image_dir:, default_key:)
      UserBotLines::RichMenus::Expo2026Campaign::NOLOGIN_KEYS.each_with_index do |key, index|
        create_campaign_menu!(
          key: key,
          image_path: image_dir.join("richmenu-nologin", "richmenu-nologin-%02d.jpg" % (index + 1)),
          default_menu: key == default_key
        )
      end

      create_campaign_menu!(
        key: UserBotLines::RichMenus::Expo2026Campaign::ONLY_EVENT_KEY,
        image_path: image_dir.join("richmenu-onlyevent", "richmenu-onlyevent-01.jpg"),
        default_menu: false
      )
    end

    def create_campaign_menu!(key:, image_path:, default_menu:)
      abort "[Expo2026] image not found: #{image_path}" unless image_path.exist?

      SocialRichMenu.where(
        social_name: key,
        locale: UserBotLines::RichMenus::Expo2026Campaign::LOCALE
      ).find_each do |rich_menu|
        RichMenus::Delete.run!(social_rich_menu: rich_menu)
      end

      body = UserBotLines::RichMenus::Expo2026Campaign.body(key)
      response = LineClient.create_rich_menu(social_account: UserBotSocialAccount, body: body)
      abort "[Expo2026] create rich menu failed: key=#{key} response=#{response&.body}" unless response.is_a?(Net::HTTPOK)

      rich_menu_id = JSON.parse(response.body).fetch("richMenuId")
      image_response = LineClient.create_rich_menu_image(
        social_account: UserBotSocialAccount,
        rich_menu_id: rich_menu_id,
        file_path: image_path.to_s
      )

      unless image_response.is_a?(Net::HTTPOK)
        UserBotSocialAccount.client.delete_rich_menu(rich_menu_id)
        abort "[Expo2026] upload rich menu image failed: key=#{key} response=#{image_response&.body}"
      end

      rich_menu = SocialRichMenu.create!(
        social_rich_menu_id: rich_menu_id,
        social_name: key,
        body: body,
        internal_name: key,
        bar_label: I18n.t("user_bot.guest.rich_menu_bar", locale: UserBotLines::RichMenus::Expo2026Campaign::LOCALE),
        default: default_menu,
        start_at: Time.current,
        end_at: UserBotLines::RichMenus::Expo2026Campaign::END_ON.end_of_day,
        locale: UserBotLines::RichMenus::Expo2026Campaign::LOCALE
      )

      if default_menu
        SocialRichMenu.where(social_account_id: nil, locale: rich_menu.locale, default: true).where.not(id: rich_menu.id).update_all(default: nil)
        response = LineClient.set_default_rich_menu(rich_menu)
        abort "[Expo2026] set default rich menu failed: key=#{key} response=#{response&.body}" unless response.is_a?(Net::HTTPOK)
      end

      puts "[Expo2026] created rich menu #{key}=#{rich_menu.social_rich_menu_id}"
    end

    def link_nologin_users!(scope)
      total = scope.count
      linked = 0
      scope.find_each do |social_user|
        UserBotLines::RichMenus::Expo2026Campaign.link_nologin_menu(social_user)
        linked += 1
        puts "[Expo2026] linked nologin users #{linked}/#{total}" if (linked % 50).zero? || linked == total
      end
    end

    def link_only_event_users!(event_line_users)
      total = event_line_users.size
      event_line_users.each_with_index do |event_line_user, index|
        UserBotLines::RichMenus::Expo2026Campaign.link_only_event_menu(event_line_user)
        puts "[Expo2026] linked only-event users #{index + 1}/#{total}" if ((index + 1) % 10).zero? || index + 1 == total
      end
    end
  end
end
