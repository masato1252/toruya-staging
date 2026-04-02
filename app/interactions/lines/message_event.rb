# frozen_string_literal: true

require "line_client"
require "message_encryptor"

class Lines::MessageEvent < ActiveInteraction::Base
  BUNDLER_SERVICE_SEPARATOR = "~"

  hash :event, strip: false, default: nil
  object :social_customer

  def execute
    is_keyword = false

    if event.present?
      case event["message"]["type"]
      when "image"
        # Rollbar.info("Line image message", event: event)

        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: {
            messageId: event["message"]["id"],
            originalContentUrl: event["message"]["contentProvider"]["originalContentUrl"],
            previewImageUrl: event["message"]["contentProvider"]["previewImageUrl"]
          }.to_json,
          readed: false,
          content_type: SocialMessages::Create::IMAGE_TYPE,
          message_type: SocialMessage.message_types[:customer]
        )
      when "text"
        # Rollbar.info("Line text message", event: event)

        function_access = keyword_in_rich_menu?(event["message"]["text"]) ? track_keyword_access(event["message"]["text"]) : nil

        case event["message"]["text"].strip
        when *I18n.available_locales.map { |locale| I18n.t("line.bot.keywords.booking_options", locale: locale) }
          is_keyword = true

          Lines::Actions::BookingOptions.run(social_customer: social_customer, function_access_id: function_access&.id)
        when *I18n.available_locales.map { |locale| I18n.t("line.bot.keywords.booking_pages", locale: locale) }, *I18n.available_locales.map { |locale| I18n.t("line.bot.legacy_keyowords.booking_pages", locale: locale) }
          is_keyword = true

          Lines::Actions::BookingPages.run(social_customer: social_customer, function_access_id: function_access&.id)
        when *I18n.available_locales.map { |locale| I18n.t("line.bot.keywords.incoming_reservations", locale: locale) }
          is_keyword = true

          if social_customer.customer
            Lines::Actions::IncomingReservations.run(social_customer: social_customer)
          else
            compose(Lines::Menus::Guest, social_customer: social_customer)
          end
        when Regexp.union(I18n.available_locales.map { |locale| I18n.t("line.bot.keywords.services", locale: locale) })
          is_keyword = true

          if social_customer.customer
            last_relation_id = event["message"]["text"].strip.match(/\d+$/).try(:[], 0)
            bundler_service_id = event["message"]["text"].strip.match(/#{BUNDLER_SERVICE_SEPARATOR}(\d+)#{BUNDLER_SERVICE_SEPARATOR}/).try(:[], 1)
            Lines::Actions::ActiveOnlineServices.run(social_customer: social_customer, bundler_service_id: bundler_service_id, last_relation_id: last_relation_id)
          else
            compose(Lines::Menus::Guest, social_customer: social_customer)
          end
        when *I18n.available_locales.map { |locale| I18n.t("line.bot.keywords.contacts", locale: locale) }
          is_keyword = true

          Lines::Actions::Contact.run(social_customer: social_customer)
        end

        is_toruya_customer_message = !is_keyword
        stripped_text = event["message"]["text"].strip

        is_owner_verification_message = social_customer.is_owner &&
          stripped_text == social_customer.social_user_id

        # Fallback: LINE Login UID ≠ Messaging API UID の場合、
        # Flexボタンが送るUIDと webhook の source.userId が異なる。
        # content が別の is_owner social_customer の UID に一致するかチェック。
        verification_sc = social_customer
        unless is_owner_verification_message
          if stripped_text.match?(/\AU[0-9a-f]{32}\z/)
            owner_sc = SocialCustomer.find_by(
              user_id: social_customer.user_id,
              social_account_id: social_customer.social_account_id,
              social_user_id: stripped_text,
              is_owner: true
            )
            if owner_sc
              is_owner_verification_message = true
              verification_sc = owner_sc
              Rails.logger.info("[LineVerification] Cross-UID fallback: webhook_sc=#{social_customer.id}(#{social_customer.social_user_id}), owner_sc=#{owner_sc.id}(#{owner_sc.social_user_id})")
            end
          end
        end

        if is_owner_verification_message
          Rails.logger.info("[LineVerification] Owner verification message detected: sc=#{verification_sc.id}, uid=#{verification_sc.social_user_id}, text=#{stripped_text}")
          compose(
            SocialMessages::Create,
            social_customer: verification_sc,
            content: stripped_text,
            readed: false,
            message_type: SocialMessage.message_types[:customer]
          )
        elsif !social_customer.customer && is_toruya_customer_message
          if social_customer.user.line_contact_customer_name_required
            compose(
              SocialMessages::Create,
              social_customer: social_customer,
              content: I18n.t("line.bot.please_use_contact_feature"),
              readed: true,
              message_type: SocialMessage.message_types[:bot]
            )
            Lines::Actions::Contact.run(social_customer: social_customer)
          else
            # avoid social_user_name is nil cause customer created failed 
            if social_customer.social_user_name.blank?
              LineProfileJob.perform_now(social_customer)
            end

            compose(
              SocialCustomers::Contact,
              social_customer: social_customer,
              content: event["message"]["text"],
              last_name: "",
              first_name: social_customer.social_user_name
            )

            # Reload to get the newly created customer
            social_customer.reload

            # Record the original message for verification purposes
            compose(
              SocialMessages::Create,
              social_customer: social_customer,
              content: event["message"]["text"],
              readed: false,
              message_type: SocialMessage.message_types[:customer]
            )
          end
        else
          compose(
            SocialMessages::Create,
            social_customer: social_customer,
            content: event["message"]["text"],
            readed: !is_toruya_customer_message,
            message_type: is_toruya_customer_message ? SocialMessage.message_types[:customer] : SocialMessage.message_types[:customer_reply_bot]
          )
        end
      else
        # Rollbar.warning("Line chat room don't support message type", event: event)

        # compose(
        #   SocialMessages::Create,
        #   social_customer: social_customer,
        #   content: I18n.t("line.bot.please_use_contact_feature"),
        #   readed: true,
        #   message_type: SocialMessage.message_types[:bot]
        # )
        # Lines::Actions::Contact.run(social_customer: social_customer)
      end
    end
  end

  private

  def keyword_in_rich_menu?(text)
    if social_customer.social_account&.using_line_official_account?
      false
    else
      mapped_text = SocialRichMenu.label_key_mapping.dig(text) || text
      SocialRichMenu.find_by(social_account_id: social_customer.social_account_id, social_name: social_customer.social_rich_menu_key )&.action_values&.include?(mapped_text)
    end
  end

  def track_keyword_access(text)
    FunctionAccess.track_access(
      content: text,
      source_type: "SocialRichMenu",
      source_id: social_customer.social_rich_menu_key,
      action_type: "keyword",
      label: text
    )
  end
end
