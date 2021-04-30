# frozen_string_literal: true

require "line_client"
# require "webpush_client"

module SocialMessages
  class Create < ActiveInteraction::Base
    object :social_customer
    object :staff, default: nil
    string :content
    boolean :readed
    integer :message_type
    time :schedule_at, default: nil
    boolean :send_line, default: true

    def execute
      message = SocialMessage.create(
        social_account: social_customer.social_account,
        social_customer: social_customer,
        staff: staff,
        raw_content: content,
        readed_at: readed ? Time.zone.now : nil,
        message_type: message_type
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif message_type == SocialMessage.message_types[:customer] || message_type == SocialMessage.message_types[:customer_reply_bot]
        # Switch user rich menu to tell users there are new messages
        if !readed && message_type == SocialMessage.message_types[:customer] && social_customer.customer
          UserBotLines::Actions::SwitchRichMenu.run(
            social_user: social_customer.user.social_user,
            rich_menu_key: UserBotLines::RichMenus::DashboardWithNotifications::KEY
          )
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
