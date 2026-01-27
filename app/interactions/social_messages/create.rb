# frozen_string_literal: true

require "line_client"
# require "webpush_client"

module SocialMessages
  class Create < ActiveInteraction::Base
    TEXT_TYPE = "text"
    VIDEO_TYPE = "video"
    IMAGE_TYPE = "image"
    FLEX_TYPE = "flex"
    CONTENT_TYPES = [TEXT_TYPE, VIDEO_TYPE, IMAGE_TYPE, FLEX_TYPE].freeze

    object :social_customer
    object :staff, default: nil
    file :image, default: nil
    string :content
    string :content_type, default: TEXT_TYPE
    boolean :readed
    integer :message_type
    time :schedule_at, default: nil
    boolean :send_line, default: true # false is for recording some behavior, usually do this with some bot flex messages
    object :broadcast, default: nil

    def execute
      is_message_from_customer = message_type == SocialMessage.message_types[:customer] || message_type == SocialMessage.message_types[:customer_reply_bot]

      message = SocialMessage.create(
        social_account: social_account,
        social_customer: social_customer,
        customer_id: social_customer.customer_id,
        user_id: social_customer.user_id,
        staff: staff,
        raw_content: content,
        content_type: content_type,
        readed_at: readed ? Time.zone.now : nil,
        sent_at: is_message_from_customer || !send_line ? Time.current : nil,
        schedule_at: schedule_at,
        message_type: message_type,
        broadcast: broadcast,
        channel: "line"
      )

      if message.errors.present?
        errors.merge!(message.errors)
        return message
      end

      if image.present?
        message.image.attach(io: image, filename: image.original_filename)
        message.update(
          raw_content: {
            originalContentUrl: Images::Process.run!(image: message.image, resize: "750"),
            previewImageUrl: Images::Process.run!(image: message.image, resize: "750")
          }.to_json
        )
      end

      if is_message_from_customer
        # TODO: Need to deal with other pending
        # Switch user rich menu to tell users there are new messages
        ::SocialMessages::HandleUnread.run(social_customer: social_customer, social_message: message)

        # Shop owner customer self send a confirmation message to toruya shop owner user
        if social_customer.is_owner && content == social_customer.social_user_id && social_customer.customer
          # Immediate execution for better UX - user sees completion message right away
          Notifiers::Users::LineSettingsVerified.perform_later(receiver: social_user.user)

          if social_account.line_settings_verified?
            social_user.user.user_setting.update(customer_notification_channel: "line")
            # Immediate execution for better UX - user sees rich menu right away
            SocialAccounts::RichMenus::CustomerReservations.perform_later(social_account: social_account)
          end
        end

        case content_type
        when IMAGE_TYPE
          SocialMessages::FetchImage.perform_later(social_message: message)
        end
      elsif send_line
        # From staff or bot
        if schedule_at
          SocialMessages::Send.perform_at!(schedule_at: schedule_at, social_message: message)
        else
          compose(SocialMessages::Send, social_message: message)
        end
      end

      message
    end

    private

    def social_account
      @social_account ||= social_customer.social_account
    end

    def user
      @user ||= social_account.user
    end

    def social_user
      @social_user ||= user.social_user
    end
  end
end
