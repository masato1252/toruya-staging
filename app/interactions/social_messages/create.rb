# frozen_string_literal: true

require "line_client"
# require "webpush_client"

module SocialMessages
  class Create < ActiveInteraction::Base
    TEXT_TYPE = "text"
    VIDEO_TYPE = "video"
    IMAGE_TYPE = "image"
    CONTENT_TYPES = [TEXT_TYPE, VIDEO_TYPE, IMAGE_TYPE].freeze

    object :social_customer
    object :staff, default: nil
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
        social_account: social_customer.social_account,
        social_customer: social_customer,
        staff: staff,
        raw_content: content,
        readed_at: readed ? Time.zone.now : nil,
        sent_at: is_message_from_customer || !send_line ? Time.current : nil,
        schedule_at: schedule_at,
        message_type: message_type,
        broadcast: broadcast
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif is_message_from_customer
        # Switch user rich menu to tell users there are new messages
        if !readed && message_type == SocialMessage.message_types[:customer] && social_customer.customer
          UserBotLines::Actions::SwitchRichMenu.run(
            social_user: social_customer.user.social_user,
            rich_menu_key: UserBotLines::RichMenus::DashboardWithNotifications::KEY
          )
        end

        case content_type
        when IMAGE_TYPE
          message_body = JSON.parse(content)
          response = LineClient.message_content(social_customer: social_customer, message_id: message_body["messageId"])
          case response
          when Net::HTTPSuccess
            tf = Tempfile.open("content", binmode: true)
            tf.write(response.body)
            tf.rewind
            message.image.attach(io: tf, filename: "img.jpg", content_type: "image/jpg")
            # message.image = tf
            message.save
          end
        end

        # From normal customer
        # UserChannel.broadcast_to(
        #   social_customer.user,
        #   {
        #     type: "customer_new_message",
        #     data: {
        #       customer: SocialCustomerSerializer.new(social_customer).attributes_hash,
        #       message: MessageSerializer.new(message).attributes_hash
        #     }
        #   }
        # )

        # WebPushSubscription.where(user_id: social_customer.user.owner_staff_accounts.active.pluck(:user_id)).each do |subscription|
        #   begin
        #     WebpushClient.send(
        #       subscription: subscription,
        #       message: {
        #         title: "#{social_customer.social_user_name} send a message",
        #         body: content,
        #         url: Rails.application.routes.url_helpers.user_chats_url(social_customer.user, customer_id: social_customer.social_user_id)
        #       }
        #     )
        #   rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription, Webpush::Unauthorized => e
        #     Rollbar.error(e)
        #
        #     subscription.destroy
        #   rescue => e
        #     Rollbar.error(e)
        #   end
        # end
      elsif !Rails.env.development? && send_line
        # From staff or bot
        if schedule_at
          SocialMessages::Send.perform_at(schedule_at: schedule_at, social_message: message)
        else
          SocialMessages::Send.run(social_message: message)
        end
      end

      message
    end
  end
end
