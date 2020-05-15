require "line_client"
require "webpush_client"

module SocialMessages
  class Create < ActiveInteraction::Base
    object :social_customer
    object :staff, default: nil
    string :content
    boolean :readed

    def execute
      message = SocialMessage.create(
        social_account: social_customer.social_account,
        social_customer: social_customer,
        staff: staff,
        raw_content: content,
        readed_at: readed ? Time.zone.now : nil
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif staff.nil?
        # From normal customer
        UserChannel.broadcast_to(
          social_customer.user,
          {
            type: "customer_new_message",
            data: {
              customer: CustomerSerializer.new(social_customer).serializable_hash[:data][:attributes],
              message: MessageSerializer.new(message).serializable_hash[:data][:attributes]
            }
          }
        )

        WebPushSubscription.where(user_id: social_customer.user.owner_staff_accounts.active.pluck(:user_id)).each do |subscription|
          begin
            WebpushClient.send(
              subscription: subscription,
              message: {
                title: "#{social_customer.social_user_name} send a message",
                body: content,
                url: Rails.application.routes.url_helpers.user_chats_url(social_customer.user, customer_id: social_customer.social_user_id)
              }
            )
          rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription, Webpush::Unauthorized => e
            Rollbar.error(e)

            subscription.destroy
          rescue => e
            Rollbar.error(e)
          end
        end
      elsif staff
        # From staff
        LineClient.send(social_customer, content) unless Rails.env.development?
      end

      message
    end
  end
end
